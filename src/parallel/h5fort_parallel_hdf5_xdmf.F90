!------------------------------------------------------------------------------
! Tohoku University, Keiriki
!------------------------------------------------------------------------------
!
! MODULE: h5fort_parallel_hdf5_xdmf
!
!> @author
!> Yuta Suzuki
!
! DESCRIPTION:
!>  Output HDF5 files and XDMF fragments for parallel visualization with ParaView.
!
! REVISION HISTORY:
!------------------------------------------------------------------------------
! module_phdf5.F90 - Parallel HDF5 ライタ (MPI-IO / Collective I/O)
!
! 既存の module_hdf5 / t_hdf5_writer と同じ呼び出し界面を保ちつつ、
! 全ランクが 1 つの共有 HDF5 ファイルへ MPI-IO で書き込む。
!
! HDF5 ファイル構造 (タイムステップごとに 1 ファイル、全ランク共有):
!   ファイル名パターン:
!     ts{ts:04d}.h5  (/ugrid + /polydata 両グループを格納)
!
!   ts{ts:04d}.h5:
!   /ugrid/
!     geometry/
!       nodes        [total_np][3]   float64   (全ランク連結)
!       connectivity [total_nc][8]   int64     (グローバルノード番号, offset_points 加算済み)
!     point_data/
!       <name>       [total_np]      or [total_np][ncomp]
!     cell_data/
!       <name>       [total_nc]
!   /polydata/
!     geometry/
!       nodes        [total_np][3]   float64
!     point_data/
!       <name>       [total_np]      or [total_np][ncomp]
!
! connectivity について:
!   呼び出し側がグローバル 0-indexed 番号に変換してから渡す。
!   (ローカル -> グローバルの変換は sample_build_comm_info 等の呼び出し側で行う)
!   XDMF がグローバル dataset を直接参照するため、グローバルノード番号で格納する。
!
! 次元の注意 (module_hdf5 と同一):
!   Fortran 配列 data(ncomp, np) (列優先) を HDF5 dims=[ncomp, np] で渡すと
!   HDF5 ファイルには C 行優先の [np][ncomp] として格納される。
!   XDMF の Dimensions 属性も C 順: "np ncomp"
!
! 使い方:
!
!   ug%h5_filepath   = 'result/phdf5/ts0000.h5'
!   ug%output_type = 'UnstructuredGrid'
!   ug%num_points  = np
!   ug%num_cells   = nc
!   ug%comm        = MPI_COMM_WORLD     ! integer MPI コミュニケータ
!   ug%me          = me_proc
!   ug%nprocs      = nprocs
!   call ug%init()     ! MPI_Allgather + ファイル新規作成（全ランク集合的）
!   call ug%write_geometry_ugrid(nodes, connectivity)
!   call ug%write_point_data(pressure, 'Pressure')
!   call ug%close()
!
!   ! PolyData は同じファイルに追記（init が既存ファイルを RDWR で再オープン）
!   pd%h5_filepath   = 'result/phdf5/ts0000.h5'
!   pd%output_type = 'PolyData'
!   ...
!   call pd%init()
!   call pd%write_geometry_polydata(nodes)
!   call pd%close()
!
!
!------------------------------------------------------------------------------
!
! write_fragment でグローバル mesh を直接参照する。
! HyperSlab / rank Grid は使わない。
! ParaView XDMF3 Reader T で読み込み可能。
!
! 断片ファイル名:
!   metadata/ts{ts:04d}_{output_type}_phdf5.xdmf.part
!
! 断片ファイル構造 (ugrid 例):
!   <Topology TopologyType="Hexahedron" NumberOfElements="1000">
!     <DataItem Format="HDF" NumberType="Int" Precision="8" Dimensions="1000 8">
!       ../phdf5/ts0000.h5:/ugrid/geometry/connectivity
!     </DataItem>
!   </Topology>
!   <Geometry GeometryType="XYZ">
!     <DataItem Format="HDF" NumberType="Float" Precision="8" Dimensions="1694 3">
!       ../phdf5/ts0000.h5:/ugrid/geometry/nodes
!     </DataItem>
!   </Geometry>
!   <Attribute Name="Pressure" AttributeType="Scalar" Center="Node">
!     <DataItem Format="HDF" NumberType="Float" Precision="8" Dimensions="1694">
!       ../phdf5/ts0000.h5:/ugrid/point_data/Pressure
!     </DataItem>
!   </Attribute>
!   ...
!
! output_xdmf がこの断片を <Grid GridType="Uniform"> でラップし、
! Temporal Collection を構成する。
!
! 最終 XDMF 構造:
!   Temporal Collection
!    ├ Uniform Grid (ts0000) ← time + fragment content
!    ├ Uniform Grid (ts0001)
!    └ ...
!
!------------------------------------------------------------------------------

module h5fort_parallel_hdf5_xdmf
  use hdf5
! # define USE_MPI_F08
# ifdef USE_MPI_F08
    use mpi_f08
# else
    use mpi
# endif
  use, intrinsic :: iso_fortran_env
  implicit none
  private

  public :: t_phdf5_writer

  ! HDF5 型 ID
  integer(HID_T) :: h5t_i32_
  integer(HID_T) :: h5t_i64_

  ! Checker flags
  logical, private :: is_file_initialized = .false.
  logical, private :: is_written_fragment = .false.


  integer, parameter :: MAX_ATTRS = 64

  type :: t_phdf5_attr_info
    character(len=64)  :: name      = ''
    character(len=16)  :: attr_type = ''   ! Scalar / Vector / Tensor6 / Tensor
    character(len=8)   :: center    = ''   ! Node / Cell
    character(len=8)   :: num_type  = ''   ! Float / Int
    integer            :: precision = 8
    integer(int64)     :: n_total   = 0    ! グローバル要素数
    integer            :: ncomp     = 1
  end type t_phdf5_attr_info

  !--------------------------------------------------------------------
  ! Parallel HDF5 writer class
  !--------------------------------------------------------------------
  type :: t_phdf5_writer
    ! Followings should be set by user before init()
    ! "UnstructuredGrid" or "PolyData"
    character(len=16) :: output_type = ''
    ! FIXME: delete this. use `h5_dir // h5_filename` instead.
    character(len=:), allocatable :: h5_filepath
    character(len=:), allocatable :: h5_dir
    ! XDMF
    ! 出力ディレクトリ (metadata/)
    character(len=:), allocatable :: metadata_dir
    ! HDF5 ファイル名 (ts0000.h5)
    character(len=:), allocatable :: h5_filename
    ! HDF5 ファイルへの相対ディレクトリ (../phdf5)
    character(len=:), allocatable :: rel_dir_meta2h5

    ! Followings should be `owned` number of points/cells for this rank, don't include ghost points/cells.
    ! But is not necessary to be exact because they can be merged in ParaView.
    integer(int64)    :: num_points  = 0_int64
    integer(int64)    :: num_cells   = 0_int64

#   ifdef USE_MPI_F08
      type(MPI_Comm), private :: comm = MPI_COMM_WORLD
#   else
      integer, private :: comm = MPI_COMM_WORLD
#   endif
    integer, private :: me = 0
    integer, private :: nprocs = 1

    ! 内部フィールド（init が設定、読み取り専用で利用可）
    integer(int64), private :: total_points  = 0_int64
    integer(int64), private :: total_cells   = 0_int64
    integer(int64), private :: offset_points = 0_int64
    integer(int64), private :: offset_cells  = 0_int64
    integer(int64), private, allocatable :: rank_np_(:)   ! (0:nprocs-1)
    integer(int64), private, allocatable :: rank_nc_(:)   ! (0:nprocs-1)

    integer(HID_T), private :: file_id   = -1
    integer(HID_T), private :: gid_geom  = -1
    integer(HID_T), private :: gid_pdata = -1
    integer(HID_T), private :: gid_cdata = -1
    integer(HID_T), private :: xfer_id   = -1   ! H5P_DATASET_XFER (Collective)

    ! XDMF fragment
    integer            :: seq    = 0
    real(real64)       :: time   = 0.0_real64
    ! zero padding
    integer            :: seq_digits = 5
    integer            :: rank_digits = 4

    ! 属性リスト
    integer, private :: n_attrs = 0
    type(t_phdf5_attr_info) :: attrs(MAX_ATTRS)

  contains
    procedure :: init               => phdf5_init
    procedure :: write_geometry_ugrid_i64 => phdf5_geom_ugrid_i64
    procedure :: write_geometry_ugrid_i32 => phdf5_geom_ugrid_i32
    generic   :: write_geometry_ugrid    => write_geometry_ugrid_i64, write_geometry_ugrid_i32
    procedure :: write_geometry_polydata => phdf5_geom_polydata
    generic   :: write_geometry => write_geometry_ugrid_i64, write_geometry_ugrid_i32, write_geometry_polydata
    procedure :: write_point_1d     => phdf5_point_1d
    procedure :: write_point_2d     => phdf5_point_2d
    generic   :: write_point_data   => write_point_1d, write_point_2d
    procedure :: write_cell_i32     => phdf5_cell_i32
    generic   :: write_cell_data    => write_cell_i32
    procedure :: close              => phdf5_close
    ! xdmf fragment
    procedure :: add_point_attr_1d   => phdf5_xdmf_add_point_1d
    procedure :: add_point_attr_2d   => phdf5_xdmf_add_point_2d
    generic   :: add_point_attr      => add_point_attr_1d, add_point_attr_2d
    procedure :: add_cell_attr_i32   => phdf5_xdmf_add_cell_i32
    generic   :: add_cell_attr       => add_cell_attr_i32
    procedure :: write_fragment          => phdf5_xdmf_write_fragment
  end type t_phdf5_writer

contains

  !====================================================================
  ! %init
  !   MPI_Allgather and offset calculation
  !   -> ファイル作成/再オープン
  !   -> グループ作成
  ! 全ランクが集合的に呼ぶ。
  ! ファイルが既に存在する場合は H5F_ACC_RDWR_F で再オープンし、
  ! 新しいグリッドタイプのグループを追記する（1ファイル/タイムステップ対応）。
  ! 注意: metadata グループ(属性)は廃止。全ランク対称になるよう非対称 I/O を排除。
  ! オフセット情報は meta_phdf5.txt に記録される。
  !====================================================================
  subroutine phdf5_init(self)
    class(t_phdf5_writer), intent(inout) :: self
    integer :: hdferr, mpi_err, r
    integer(HID_T) :: fapl_id, gid_base
    logical :: file_exists
    integer :: iexist   ! 0 or 1 for MPI_Bcast
    integer :: ierr
    integer(HID_T) :: obj_count

    ! Check flags and required fields
#   define ABORT(msg,X) \
      write(error_unit,'(a)') 'PHDF5-ERROR detected in phdf5 init'; \
      write(error_unit,'(a)') msg; \
      call MPI_Abort(self%comm, X, mpi_err)
    if (is_file_initialized) then
      ABORT("This file is already initialized",2)
    end if
#   undef ABORT
    is_file_initialized = .true.

    ! Set MPI rank and size
    call MPI_Comm_rank(self%comm, self%me, mpi_err)
    call MPI_Comm_size(self%comm, self%nprocs, mpi_err)

    !------------------------------------------------------------------
    ! MPI_Allgather で各ランクの num_points / num_cells を収集
    !------------------------------------------------------------------
    allocate(self%rank_np_(0:self%nprocs-1))
    allocate(self%rank_nc_(0:self%nprocs-1))

    call MPI_Allgather(self%num_points, 1, MPI_INTEGER8, self%rank_np_,  1, MPI_INTEGER8, self%comm, mpi_err)
    call MPI_Allgather(self%num_cells,  1, MPI_INTEGER8, self%rank_nc_,  1, MPI_INTEGER8, self%comm, mpi_err)

    ! offset と total を計算
    self%total_points = 0
    self%total_cells = 0
    self%offset_points = 0
    self%offset_cells = 0
    do r = 0, self%nprocs - 1
      if (r < self%me) then
        self%offset_points = self%offset_points + self%rank_np_(r)
        self%offset_cells  = self%offset_cells  + self%rank_nc_(r)
      end if
      self%total_points = self%total_points + self%rank_np_(r)
      self%total_cells  = self%total_cells  + self%rank_nc_(r)
    end do

    ! Determine base group: UnstructuredGrid or PolyData
    select case (trim(self%output_type))
    case ('UnstructuredGrid', 'ugrid', 'unstructuredgrid', 'UGRID', 'vtu', 'VTU', 'Unstructured', 'unstructured')
      self%output_type = 'ugrid'
    case ('PolyData', 'polydata', 'POLYDATA', 'vtp', 'VTP', 'PointData', 'pointdata', 'POINTDATA', 'Point', 'point')
      self%output_type = 'polydata'
    case default
      if (self%me == 0) then
        write(error_unit,'(a)') 'ERROR phdf5_init: unknown output_type: ' // trim(self%output_type)
      end if
      call MPI_Abort(self%comm, 1, mpi_err)
    end select

    !------------------------------------------------------------------
    ! MPI-IO ファイルアクセス Property List を作成
    !------------------------------------------------------------------
    call h5pcreate_f(H5P_FILE_ACCESS_F, fapl_id, hdferr)
    call h5pset_fapl_mpio_f(fapl_id, self%comm, MPI_INFO_NULL, hdferr)
    ! 注意: coll_metadata_write / all_coll_metadata_ops は rank 0 のみが
    ! 属性を書く独立 I/O と競合して metadata checksum を破壊するため使わない。
    ! データセット書き込みの Collective I/O は xfer_id (H5FD_MPIO_COLLECTIVE_F) で行う。

    !------------------------------------------------------------------
    ! ファイルの存在確認（rank 0 で判定 -> MPI_Bcast で全ランクに伝播）
    ! クラスタファイルシステムのキャッシュ遅延を回避するため rank 0 のみチェック。
    !------------------------------------------------------------------
    if (self%me == 0) then
      inquire(file=trim(self%h5_filepath), exist=file_exists)
      if (file_exists) then
        iexist = 1
      else
        iexist = 0
      end if
    end if
    call MPI_Bcast(iexist, 1, MPI_INTEGER, 0, self%comm, mpi_err)
    file_exists = (iexist == 1)

    !------------------------------------------------------------------
    ! ファイルをオープン（全ランク集合的）
    ! 既存ファイルがあれば RDWR で再オープン、なければ新規作成。
    ! 1 タイムステップ内で ugrid -> polydata の順に同じファイルへ追記する。
    !------------------------------------------------------------------
    if (file_exists) then
      call h5fopen_f(trim(self%h5_filepath), H5F_ACC_RDWR_F, self%file_id, hdferr, access_prp=fapl_id)
    else
      call h5fcreate_f(trim(self%h5_filepath), H5F_ACC_TRUNC_F, self%file_id, hdferr, access_prp=fapl_id)
    end if
    call h5pclose_f(fapl_id, hdferr)

    if (hdferr /= 0) then
      write(error_unit,'(a,a)') 'ERROR phdf5_init: cannot open/create ', trim(self%h5_filepath)
      call MPI_Abort(self%comm, 1, mpi_err)
    end if

    !------------------------------------------------------------------
    ! グループ作成（全ランク集合的）
    !------------------------------------------------------------------
    call h5gcreate_f(self%file_id, trim(self%output_type), gid_base, hdferr)

    ! geometry, point_data グループ（全ランク集合的）
    call h5gcreate_f(gid_base, 'geometry',   self%gid_geom,  hdferr)
    call h5gcreate_f(gid_base, 'point_data', self%gid_pdata, hdferr)

    ! Add `cell_data` group only for UnstructuredGrid
    self%gid_cdata = -1
    if (trim(self%output_type) == 'ugrid') then
      call h5gcreate_f(gid_base, 'cell_data', self%gid_cdata, hdferr)
    end if

    call h5gclose_f(gid_base, hdferr)

    !------------------------------------------------------------------
    ! Dataset transfer property list: Collective I/O を設定
    !------------------------------------------------------------------
    call h5pcreate_f(H5P_DATASET_XFER_F, self%xfer_id, hdferr)
    call h5pset_dxpl_mpio_f(self%xfer_id, H5FD_MPIO_COLLECTIVE_F, hdferr)
  end subroutine phdf5_init

  !====================================================================
  ! write_geometry_ugrid: nodes + connectivity -> /geometry
  ! connectivity はグローバル 0-indexed で渡す（呼び出し側が変換済み）。
  !====================================================================
  subroutine phdf5_geom_ugrid_i64(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(3, self%num_points)
    integer(int64), intent(in) :: connectivity(8, self%num_cells)

    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_r64_2d_slab_(self%gid_geom, 'nodes', 3_int64, &
                            self%num_points, self%offset_points, self%total_points, &
                            nodes, self%xfer_id)

    ! connectivity: グローバル 0-indexed をそのまま書き込む
    call write_i64_2d_slab_(self%gid_geom, 'connectivity', 8_int64, &
                            self%num_cells, self%offset_cells, self%total_cells, &
                            connectivity, self%xfer_id)
  end subroutine phdf5_geom_ugrid_i64
  subroutine phdf5_geom_ugrid_i32(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(3, self%num_points)
    integer(int32), intent(in) :: connectivity(8, self%num_cells)

    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_r64_2d_slab_(self%gid_geom, 'nodes', 3_int64, &
                            self%num_points, self%offset_points, self%total_points, &
                            nodes, self%xfer_id)

    ! connectivity: グローバル 0-indexed をそのまま書き込む
    call write_i32_2d_slab_(self%gid_geom, 'connectivity', 8_int32, &
                            self%num_cells, self%offset_cells, self%total_cells, &
                            connectivity, self%xfer_id)
  end subroutine phdf5_geom_ugrid_i32

  !====================================================================
  ! write_geometry_polydata: nodes のみ -> /geometry
  !====================================================================
  subroutine phdf5_geom_polydata(self, nodes)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: nodes(3, self%num_points)

    call write_r64_2d_slab_(self%gid_geom, 'nodes', 3_int64, &
                            self%num_points, self%offset_points, self%total_points, &
                            nodes, self%xfer_id)
  end subroutine phdf5_geom_polydata

  !====================================================================
  ! write_point_data (1D スカラー)
  !====================================================================
  subroutine phdf5_point_1d(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),     intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    call write_r64_1d_slab_(self%gid_pdata, trim(field_name), &
                            self%num_points, self%offset_points, self%total_points, &
                            data, self%xfer_id)
  end subroutine phdf5_point_1d

  !====================================================================
  ! write_point_data (2D: ベクトル / 対称テンソル)
  !====================================================================
  subroutine phdf5_point_2d(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),     intent(in) :: data(:,:)
    character(len=*), intent(in) :: field_name

    call write_r64_2d_slab_(self%gid_pdata, trim(field_name), &
                            int(size(data, 1), int64), int(size(data, 2), int64), &
                            self%offset_points, self%total_points, &
                            data, self%xfer_id)
  end subroutine phdf5_point_2d

  !====================================================================
  ! write_cell_data (int32 スカラー)
  !====================================================================
  subroutine phdf5_cell_i32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int32),   intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_i32: cell_data group not open'
      stop 1
    end if
    call write_i32_1d_slab_(self%gid_cdata, trim(field_name), &
                            self%num_cells, self%offset_cells, self%total_cells, &
                            data, self%xfer_id)
  end subroutine phdf5_cell_i32

  !====================================================================
  ! close: グループ・Property List・ファイルを閉じる
  !====================================================================
  subroutine phdf5_close(self)
    class(t_phdf5_writer), intent(inout) :: self
    integer :: hdferr

    call h5gclose_f(self%gid_geom,  hdferr)
    call h5gclose_f(self%gid_pdata, hdferr)
    if (self%gid_cdata >= 0) call h5gclose_f(self%gid_cdata, hdferr)
    call h5pclose_f(self%xfer_id, hdferr)
    ! 全データをディスクにフラッシュしてからファイルを閉じる
    call h5fflush_f(self%file_id, H5F_SCOPE_GLOBAL_F, hdferr)
    call h5fclose_f(self%file_id, hdferr)

    self%file_id   = -1
    self%gid_geom  = -1
    self%gid_pdata = -1
    self%gid_cdata = -1
    self%xfer_id   = -1

    if (allocated(self%rank_np_)) deallocate(self%rank_np_)
    if (allocated(self%rank_nc_)) deallocate(self%rank_nc_)
    is_file_initialized = .false.
  end subroutine phdf5_close

  !====================================================================
  ! プライベートヘルパー: HDF5 スラブ書き込み
  !
  ! 命名規則: write_{type}_{dim}d_slab_
  !   n      : このランクのローカル要素数
  !   offset : グローバルオフセット
  !   total_n: グローバル合計要素数
  !
  ! 空ランク (n=0) の処理:
  !   ファイルデータスペース: H5S_SELECT_NONE を選択
  !   メモリデータスペース : H5S_NULL (要素なし)
  !   -> 全ランクが Collective I/O に参加しつつデータ転送なし
  !====================================================================

  ! float64 1D: [total_n] に [offset, offset+n) を書く
  subroutine write_r64_1d_slab_(gid, dname, n, offset, total_n, data, xfer_id)
    integer(HID_T),   intent(in) :: gid, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64),   intent(in) :: n, offset, total_n
    real(real64),     intent(in) :: data(*)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)

    dims_f(1) = int(total_n, HSIZE_T)
    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, H5T_NATIVE_DOUBLE, fsid, did, hdferr)

    dims_m(1) = int(max(n, 1_int64), HSIZE_T)   ! ダミー値 (n=0 時)
    if (n > 0) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(n,      HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      dims_m(1) = int(n, HSIZE_T)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(did, H5T_NATIVE_DOUBLE, data, dims_m, hdferr, &
                    mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)

    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_r64_1d_slab_

  ! float64 2D: Fortran (ncomp, n) -> HDF5 C [total_n][ncomp]
  subroutine write_r64_2d_slab_(gid, dname, ncomp, n, offset, total_n, data, xfer_id)
    integer(HID_T),   intent(in) :: gid, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64),   intent(in) :: ncomp, n, offset, total_n
    real(real64),     intent(in) :: data(ncomp, *)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)

    ! Fortran 列優先 (ncomp, n) -> HDF5 API では dims(1) が速変方向
    ! ファイルには C 行優先 [total_n][ncomp] として格納
    dims_f(1) = int(ncomp,   HSIZE_T)
    dims_f(2) = int(total_n, HSIZE_T)
    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, H5T_NATIVE_DOUBLE, fsid, did, hdferr)

    dims_m(1) = int(ncomp, HSIZE_T)
    dims_m(2) = int(max(n, 1_int64), HSIZE_T)   ! ダミー値 (n=0 時)
    if (n > 0) then
      hstart(1) = 0_HSIZE_T        ! ncomp 方向は全成分
      hstart(2) = int(offset, HSIZE_T)
      hcount(1) = int(ncomp, HSIZE_T)
      hcount(2) = int(n,     HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      dims_m(2) = int(n, HSIZE_T)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(did, H5T_NATIVE_DOUBLE, data, dims_m, hdferr, &
                    mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_r64_2d_slab_

  ! int32 1D: [total_n] に [offset, offset+n) を書く
  subroutine write_i32_1d_slab_(gid, dname, n, offset, total_n, data, xfer_id)
    integer(HID_T),   intent(in) :: gid, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64),   intent(in) :: n, offset, total_n
    integer(int32),   intent(in) :: data(*)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)

    dims_f(1) = int(total_n, HSIZE_T)
    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    h5t_i32_ = h5kind_to_type(int32, H5_INTEGER_KIND)
    call h5dcreate_f(gid, dname, h5t_i32_, fsid, did, hdferr)

    dims_m(1) = int(max(n, 1_int64), HSIZE_T)   ! ダミー値 (n=0 時)
    if (n > 0) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(n,      HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      dims_m(1) = int(n, HSIZE_T)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(did, h5t_i32_, data, dims_m, hdferr, &
                    mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_i32_1d_slab_

  ! int64 2D: Fortran (ncomp, n) -> HDF5 C [total_n][ncomp]
  subroutine write_i64_2d_slab_(gid, dname, ncomp, n, offset, total_n, data, xfer_id)
    integer(HID_T),   intent(in) :: gid, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64),   intent(in) :: ncomp, n, offset, total_n
    integer(int64),   intent(in) :: data(ncomp, *)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)

    dims_f(1) = int(ncomp,   HSIZE_T)
    dims_f(2) = int(total_n, HSIZE_T)
    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    h5t_i64_ = h5kind_to_type(int64, H5_INTEGER_KIND)
    call h5dcreate_f(gid, dname, h5t_i64_, fsid, did, hdferr)

    dims_m(1) = int(ncomp, HSIZE_T)
    dims_m(2) = int(max(n, 1_int64), HSIZE_T)   ! ダミー値 (n=0 時)
    if (n > 0) then
      hstart(1) = 0_HSIZE_T
      hstart(2) = int(offset, HSIZE_T)
      hcount(1) = int(ncomp, HSIZE_T)
      hcount(2) = int(n,     HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      dims_m(2) = int(n, HSIZE_T)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(did, h5t_i64_, data, dims_m, hdferr, &
                    mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_i64_2d_slab_
  subroutine write_i32_2d_slab_(gid, dname, ncomp, n, offset, total_n, data, xfer_id)
    integer(HID_T),   intent(in) :: gid, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64),   intent(in) :: ncomp, n, offset, total_n
    integer(int32),   intent(in) :: data(ncomp, *)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)

    dims_f(1) = int(ncomp,   HSIZE_T)
    dims_f(2) = int(total_n, HSIZE_T)
    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    h5t_i32_ = h5kind_to_type(int32, H5_INTEGER_KIND)
    call h5dcreate_f(gid, dname, h5t_i32_, fsid, did, hdferr)

    dims_m(1) = int(ncomp, HSIZE_T)
    dims_m(2) = int(max(n, 1_int64), HSIZE_T)   ! ダミー値 (n=0 時)
    if (n > 0) then
      hstart(1) = 0_HSIZE_T
      hstart(2) = int(offset, HSIZE_T)
      hcount(1) = int(ncomp, HSIZE_T)
      hcount(2) = int(n,     HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      dims_m(2) = int(n, HSIZE_T)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(did, h5t_i32_, data, dims_m, hdferr, &
                    mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_i32_2d_slab_

  ! --------------------------------------------------------------------
  ! int_fmt_: 整数を指定桁数でゼロ埋めした文字列に変換する内部ヘルパー
  ! 例: int_fmt_(42, 4) -> '0042'
  ! --------------------------------------------------------------------
  function int_fmt_(val, digits) result(s)
    integer, intent(in) :: val, digits
    character(len=32) :: s, fmt
    write(fmt,'(a,i0,a,i0,a)') '(i', max(digits, 20), '.', digits, ')'
    write(s, fmt) val
    s = adjustl(s)
  end function int_fmt_

  ! --------------------------------------------------------------------
  ! add_point_attr_1d: スカラー点属性を登録
  ! --------------------------------------------------------------------
  subroutine phdf5_xdmf_add_point_1d(self, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    character(len=*), intent(in) :: field_name

    self%n_attrs = self%n_attrs + 1
    if (self%n_attrs > MAX_ATTRS) then
      write(error_unit,'(a)') 'ERROR phdf5_xdmf: too many attributes'
      stop 1
    end if
    associate(a => self%attrs(self%n_attrs))
      a%name      = trim(field_name)
      a%attr_type = 'Scalar'
      a%center    = 'Node'
      a%num_type  = 'Float'
      a%precision = 8
      a%n_total   = self%total_points
      a%ncomp     = 1
    end associate
  end subroutine phdf5_xdmf_add_point_1d

  ! --------------------------------------------------------------------
  ! add_point_attr_2d: ベクトル / テンソル点属性を登録
  ! --------------------------------------------------------------------
  subroutine phdf5_xdmf_add_point_2d(self, ncomp, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer,          intent(in) :: ncomp
    character(len=*), intent(in) :: field_name

    self%n_attrs = self%n_attrs + 1
    if (self%n_attrs > MAX_ATTRS) then
      write(error_unit,'(a)') 'ERROR phdf5_xdmf: too many attributes'
      stop 1
    end if
    associate(a => self%attrs(self%n_attrs))
      a%name    = trim(field_name)
      a%center  = 'Node'
      a%num_type  = 'Float'
      a%precision = 8
      a%n_total = self%total_points
      a%ncomp   = ncomp
      if (ncomp == 1) then
        a%attr_type = 'Scalar'
      else if (ncomp == 3) then
        a%attr_type = 'Vector'
      else if (ncomp == 6) then
        a%attr_type = 'Tensor6'
      else if (ncomp == 9) then
        a%attr_type = 'Tensor'
      else
        write(error_unit,'(a,i0,a)') 'ERROR phdf5_xdmf: unsupported ncomp for point attribute: ', ncomp, ' (only 1,3,6,9 supported)'
      end if
    end associate
  end subroutine phdf5_xdmf_add_point_2d

  ! --------------------------------------------------------------------
  ! add_cell_attr_i32: int32 スカラーセル属性を登録
  ! --------------------------------------------------------------------
  subroutine phdf5_xdmf_add_cell_i32(self, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    character(len=*), intent(in) :: field_name

    self%n_attrs = self%n_attrs + 1
    if (self%n_attrs > MAX_ATTRS) then
      write(error_unit,'(a)') 'ERROR phdf5_xdmf: too many attributes'
      stop 1
    end if
    associate(a => self%attrs(self%n_attrs))
      a%name      = trim(field_name)
      a%attr_type = 'Scalar'
      a%center    = 'Cell'
      a%num_type  = 'Int'
      a%precision = 4
      a%n_total   = self%total_cells
      a%ncomp     = 1
    end associate
  end subroutine phdf5_xdmf_add_cell_i32

  ! --------------------------------------------------------------------
  ! write_fragment: .xdmf.part ファイルを直接書く（rank 0 のみ呼ぶ）
  !
  ! グローバル dataset を直接参照する。
  ! Topology, Geometry, Attribute のみを含む（Grid タグは output_xdmf が付与）。
  ! --------------------------------------------------------------------
  subroutine phdf5_xdmf_write_fragment(self)
    class(t_phdf5_writer), intent(in) :: self
    character(len=512) :: part_path, h5_rel_path, group_prefix
    character(len=30) :: time_str
    integer :: u, i

    ! .xdmf.part ファイルのパス
    write(part_path,'(a,a,a,a,a,a)') &
      trim(self%metadata_dir), '/seq', trim(int_fmt_(self%seq, self%seq_digits)), '_', &
      trim(self%output_type), '_phdf5.xdmf.part'

    ! HDF5 ファイルへの相対パス (from metadata dir): e.g. ../phdf5/ts0000.h5
    h5_rel_path = trim(self%rel_dir_meta2h5) // '/' // trim(self%h5_filename)

    ! HDF5 グループのプリフィックス
    group_prefix = trim(self%output_type)

    open(newunit=u, file=trim(part_path), status='replace', action='write')

    write(time_str, '(es22.15e2)') self%time
    write(u,'(a,a,a)') '<Time Value="', trim(time_str), '"/>'

    ! FIXME: Precision を判定する
    ! Topology
    if (trim(self%output_type) == 'ugrid') then
      write(u,'(a,i0,a)') '<Topology TopologyType="Hexahedron" NumberOfElements="', self%total_cells, '">'
      write(u,'(a,i0,a)') '  <DataItem Format="HDF" NumberType="Int" Precision="8" Dimensions="', self%total_cells, ' 8">'
      write(u,'(a,a,a,a,a)') '    ', trim(h5_rel_path), ':/', trim(group_prefix), '/geometry/connectivity'
      write(u,'(a)') '  </DataItem>'
      write(u,'(a)') '</Topology>'
    else
      write(u,'(a,i0,a)') '<Topology TopologyType="Polyvertex" NumberOfElements="', self%total_points, '" NodesPerElement="1"/>'
    end if

    ! FIXME: Precision を判定する
    ! Geometry
    write(u,'(a)') '<Geometry GeometryType="XYZ">'
    write(u,'(a,i0,a)') '  <DataItem Format="HDF" NumberType="Float" Precision="8" Dimensions="', self%total_points, ' 3">'
    write(u,'(a,a,a,a,a)') '    ', trim(h5_rel_path), ':/', trim(group_prefix), '/geometry/nodes'
    write(u,'(a)') '  </DataItem>'
    write(u,'(a)') '</Geometry>'

    ! Attributes
    do i = 1, self%n_attrs
      call write_global_attribute_(u, h5_rel_path, group_prefix, self%attrs(i))
    end do

    close(u)
  end subroutine phdf5_xdmf_write_fragment

  ! --------------------------------------------------------------------
  ! 内部ヘルパー: 属性要素を書く（グローバル dataset 直接参照）
  ! --------------------------------------------------------------------
  subroutine write_global_attribute_(u, h5_rel, group_prefix, attr)
    integer, intent(in) :: u
    character(len=*), intent(in) :: h5_rel, group_prefix
    type(t_phdf5_attr_info), intent(in) :: attr
    character(len=32) :: data_group

    if (trim(attr%center) == 'Node') then
      data_group = 'point_data'
    else
      data_group = 'cell_data'
    end if

    write(u,'(a,a,a,a,a,a,a)') '<Attribute Name="', trim(attr%name), &
      '" AttributeType="', trim(attr%attr_type), '" Center="', trim(attr%center), '">'

    if (attr%ncomp == 1) then
      write(u,'(a,a,a,i0,a,i0,a)') &
        '  <DataItem Format="HDF" NumberType="', trim(attr%num_type), &
        '" Precision="', attr%precision, '" Dimensions="', attr%n_total, '">'
    else
      write(u,'(a,a,a,i0,a,i0,a,i0,a)') &
        '  <DataItem Format="HDF" NumberType="', trim(attr%num_type), &
        '" Precision="', attr%precision, '" Dimensions="', attr%n_total, &
        ' ', attr%ncomp, '">'
    end if

    write(u,'(a,a,a,a,a,a,a)') '    ', trim(h5_rel), ':/', &
      trim(group_prefix), '/', trim(data_group), '/' // trim(attr%name)
    write(u,'(a)') '  </DataItem>'
    write(u,'(a)') '</Attribute>'
  end subroutine write_global_attribute_

end module h5fort_parallel_hdf5_xdmf
