

! DO NOT EDIT — generated from src/fypp/parallel/h5fort_parallel_visualization.fypp
! To regenerate: src/fypp/generate_fypp.sh

module h5fort_parallel_visualization
  use h5fort_version, only: H5FORTRAN_SCHEME_VERSION
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

  ! Checker flag
  logical, private :: is_file_initialized = .false.

  !--------------------------------------------------------------------
  ! Parallel HDF5 writer class
  !--------------------------------------------------------------------
  type :: t_phdf5_writer
    ! Followings should be set by user before init()
    ! "UnstructuredGrid" or "PolyData"
    character(len=16) :: output_type = ''
    ! HDF5 group name and XDMF topology metadata.  For UnstructuredGrid,
    ! blank/zero values default to ugrid/Hexahedron/8.
    character(len=64) :: mesh_name = ''
    character(len=32) :: topology_type = ''
    integer :: nodes_per_element = 0
    ! Output HDF5 path (one file per time step).
    character(len=:), allocatable :: h5_filepath

    ! num_cells is the number of owned cells written by this rank.
    ! num_points includes every local node referenced by those cells; shared
    ! boundary/halo node copies may be duplicated between ranks.
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

    ! Root metadata read by the Python postprocessor.
    real(real64)       :: time   = 0.0_real64

  contains
    procedure :: init  => phdf5_init
    procedure :: close => phdf5_close

    procedure :: write_geometry_ugrid_real32_int8 => phdf5_write_geom_ugrid_real32_int8
    procedure :: write_geometry_ugrid_real32_int16 => phdf5_write_geom_ugrid_real32_int16
    procedure :: write_geometry_ugrid_real32_int32 => phdf5_write_geom_ugrid_real32_int32
    procedure :: write_geometry_ugrid_real32_int64 => phdf5_write_geom_ugrid_real32_int64
    procedure :: write_geometry_polydata_real32 => phdf5_geom_polydata_real32
    procedure :: write_geometry_ugrid_real64_int8 => phdf5_write_geom_ugrid_real64_int8
    procedure :: write_geometry_ugrid_real64_int16 => phdf5_write_geom_ugrid_real64_int16
    procedure :: write_geometry_ugrid_real64_int32 => phdf5_write_geom_ugrid_real64_int32
    procedure :: write_geometry_ugrid_real64_int64 => phdf5_write_geom_ugrid_real64_int64
    procedure :: write_geometry_polydata_real64 => phdf5_geom_polydata_real64
    procedure :: write_geometry_ugrid_real128_int8 => phdf5_write_geom_ugrid_real128_int8
    procedure :: write_geometry_ugrid_real128_int16 => phdf5_write_geom_ugrid_real128_int16
    procedure :: write_geometry_ugrid_real128_int32 => phdf5_write_geom_ugrid_real128_int32
    procedure :: write_geometry_ugrid_real128_int64 => phdf5_write_geom_ugrid_real128_int64
    procedure :: write_geometry_polydata_real128 => phdf5_geom_polydata_real128
    ! Compatibility names from the former hand-written implementation.
    procedure :: write_geometry_ugrid_i64 => phdf5_write_geom_ugrid_real64_int64
    procedure :: write_geometry_ugrid_i32 => phdf5_write_geom_ugrid_real64_int32
    procedure :: write_geometry_polydata  => phdf5_geom_polydata_real64
    generic   :: write_geometry_ugrid => &
      write_geometry_ugrid_real32_int8, &
      write_geometry_ugrid_real32_int16, &
      write_geometry_ugrid_real32_int32, &
      write_geometry_ugrid_real32_int64, &
      write_geometry_ugrid_real64_int8, &
      write_geometry_ugrid_real64_int16, &
      write_geometry_ugrid_real64_int32, &
      write_geometry_ugrid_real64_int64, &
      write_geometry_ugrid_real128_int8, &
      write_geometry_ugrid_real128_int16, &
      write_geometry_ugrid_real128_int32, &
      write_geometry_ugrid_real128_int64
    generic   :: write_geometry => &
      write_geometry_ugrid_real32_int8, &
      write_geometry_ugrid_real32_int16, &
      write_geometry_ugrid_real32_int32, &
      write_geometry_ugrid_real32_int64, &
      write_geometry_ugrid_real64_int8, &
      write_geometry_ugrid_real64_int16, &
      write_geometry_ugrid_real64_int32, &
      write_geometry_ugrid_real64_int64, &
      write_geometry_ugrid_real128_int8, &
      write_geometry_ugrid_real128_int16, &
      write_geometry_ugrid_real128_int32, &
      write_geometry_ugrid_real128_int64, &
      write_geometry_polydata_real32, &
      write_geometry_polydata_real64, &
      write_geometry_polydata_real128

    procedure :: write_point_1d_int8 => phdf5_point_1d_int8
    procedure :: write_cell_1d_int8  => phdf5_cell_1d_int8
    procedure :: write_point_2d_int8 => phdf5_point_2d_int8
    procedure :: write_cell_2d_int8  => phdf5_cell_2d_int8
    procedure :: write_point_1d_int16 => phdf5_point_1d_int16
    procedure :: write_cell_1d_int16  => phdf5_cell_1d_int16
    procedure :: write_point_2d_int16 => phdf5_point_2d_int16
    procedure :: write_cell_2d_int16  => phdf5_cell_2d_int16
    procedure :: write_point_1d_int32 => phdf5_point_1d_int32
    procedure :: write_cell_1d_int32  => phdf5_cell_1d_int32
    procedure :: write_point_2d_int32 => phdf5_point_2d_int32
    procedure :: write_cell_2d_int32  => phdf5_cell_2d_int32
    procedure :: write_point_1d_int64 => phdf5_point_1d_int64
    procedure :: write_cell_1d_int64  => phdf5_cell_1d_int64
    procedure :: write_point_2d_int64 => phdf5_point_2d_int64
    procedure :: write_cell_2d_int64  => phdf5_cell_2d_int64
    procedure :: write_point_1d_real32 => phdf5_point_1d_real32
    procedure :: write_cell_1d_real32  => phdf5_cell_1d_real32
    procedure :: write_point_2d_real32 => phdf5_point_2d_real32
    procedure :: write_cell_2d_real32  => phdf5_cell_2d_real32
    procedure :: write_point_1d_real64 => phdf5_point_1d_real64
    procedure :: write_cell_1d_real64  => phdf5_cell_1d_real64
    procedure :: write_point_2d_real64 => phdf5_point_2d_real64
    procedure :: write_cell_2d_real64  => phdf5_cell_2d_real64
    procedure :: write_point_1d_real128 => phdf5_point_1d_real128
    procedure :: write_cell_1d_real128  => phdf5_cell_1d_real128
    procedure :: write_point_2d_real128 => phdf5_point_2d_real128
    procedure :: write_cell_2d_real128  => phdf5_cell_2d_real128

    ! Compatibility names for callers that used the specific bindings.
    procedure :: write_point_1d => phdf5_point_1d_real64
    procedure :: write_point_2d => phdf5_point_2d_real64
    procedure :: write_cell_i32 => phdf5_cell_1d_int32
    generic   :: write_point_data => &
      write_point_1d_int8, &
      write_point_2d_int8, &
      write_point_1d_int16, &
      write_point_2d_int16, &
      write_point_1d_int32, &
      write_point_2d_int32, &
      write_point_1d_int64, &
      write_point_2d_int64, &
      write_point_1d_real32, &
      write_point_2d_real32, &
      write_point_1d_real64, &
      write_point_2d_real64, &
      write_point_1d_real128, &
      write_point_2d_real128
    generic   :: write_cell_data => &
      write_cell_1d_int8, &
      write_cell_2d_int8, &
      write_cell_1d_int16, &
      write_cell_2d_int16, &
      write_cell_1d_int32, &
      write_cell_2d_int32, &
      write_cell_1d_int64, &
      write_cell_2d_int64, &
      write_cell_1d_real32, &
      write_cell_2d_real32, &
      write_cell_1d_real64, &
      write_cell_2d_real64, &
      write_cell_1d_real128, &
      write_cell_2d_real128

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
      if (len_trim(self%mesh_name) == 0) self%mesh_name = 'ugrid'
      if (len_trim(self%topology_type) == 0 .and. self%nodes_per_element == 0) then
        self%topology_type = 'Hexahedron'
        self%nodes_per_element = 8
      else if (len_trim(self%topology_type) == 0 .or. self%nodes_per_element <= 0) then
        if (self%me == 0) then
          write(error_unit,'(a)') 'ERROR phdf5_init: topology_type and nodes_per_element must be set together'
        end if
        call MPI_Abort(self%comm, 1, mpi_err)
      end if
    case ('PolyData', 'polydata', 'POLYDATA', 'vtp', 'VTP', 'PointData', 'pointdata', 'POINTDATA', 'Point', 'point')
      self%output_type = 'polydata'
      if (len_trim(self%mesh_name) == 0) self%mesh_name = 'polydata'
      self%topology_type = 'Polyvertex'
      self%nodes_per_element = 1
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

    if (.not. file_exists) then
      call write_int32_attribute_(self%file_id, 'scheme_version', &
                                 int(H5FORTRAN_SCHEME_VERSION, int32))
      call write_real64_attribute_(self%file_id, 'time', self%time)
    end if

    !------------------------------------------------------------------
    ! グループ作成（全ランク集合的）
    !------------------------------------------------------------------
    call h5gcreate_f(self%file_id, trim(self%mesh_name), gid_base, hdferr)

    ! geometry, point_data グループ（全ランク集合的）
    call h5gcreate_f(gid_base, 'geometry',   self%gid_geom,  hdferr)
    call h5gcreate_f(gid_base, 'point_data', self%gid_pdata, hdferr)

    ! Add `cell_data` group only for UnstructuredGrid
    self%gid_cdata = -1
    if (trim(self%output_type) == 'ugrid') then
      call h5gcreate_f(gid_base, 'cell_data', self%gid_cdata, hdferr)
    end if
    call write_string_attribute_(gid_base, 'topology_type', trim(self%topology_type))
    call write_int32_attribute_(gid_base, 'nodes_per_element', int(self%nodes_per_element, int32))

    call h5gclose_f(gid_base, hdferr)

    !------------------------------------------------------------------
    ! Dataset transfer property list: Collective I/O を設定
    !------------------------------------------------------------------
    call h5pcreate_f(H5P_DATASET_XFER_F, self%xfer_id, hdferr)
    call h5pset_dxpl_mpio_f(self%xfer_id, H5FD_MPIO_COLLECTIVE_F, hdferr)
  end subroutine phdf5_init

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
  ! write_geometry_ugrid: nodes + connectivity -> /geometry
  !   connectivity は rank-local 0-origin node ID で渡す。
  !   HDF5 へ書くときに、この writer が rank の global output offset を加える。
  ! write_geometry_polydata: nodes のみ -> /geometry
  !====================================================================
  subroutine phdf5_write_geom_ugrid_real32_int8(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int8), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int8_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int8), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real32_int8

  subroutine phdf5_write_geom_ugrid_real32_int16(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int16), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int16_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int16), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real32_int16

  subroutine phdf5_write_geom_ugrid_real32_int32(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int32), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int32_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int32), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real32_int32

  subroutine phdf5_write_geom_ugrid_real32_int64(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int64), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int64_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int64), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real32_int64

  subroutine phdf5_geom_polydata_real32(self, nodes)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: nodes(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)
  end subroutine phdf5_geom_polydata_real32

  subroutine phdf5_write_geom_ugrid_real64_int8(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int8), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int8_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int8), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real64_int8

  subroutine phdf5_write_geom_ugrid_real64_int16(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int16), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int16_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int16), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real64_int16

  subroutine phdf5_write_geom_ugrid_real64_int32(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int32), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int32_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int32), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real64_int32

  subroutine phdf5_write_geom_ugrid_real64_int64(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int64), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int64_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int64), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real64_int64

  subroutine phdf5_geom_polydata_real64(self, nodes)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: nodes(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)
  end subroutine phdf5_geom_polydata_real64

  subroutine phdf5_write_geom_ugrid_real128_int8(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int8), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int8_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int8), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real128_int8

  subroutine phdf5_write_geom_ugrid_real128_int16(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int16), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int16_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int16), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real128_int16

  subroutine phdf5_write_geom_ugrid_real128_int32(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int32), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int32_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int32), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real128_int32

  subroutine phdf5_write_geom_ugrid_real128_int64(self, nodes, connectivity)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int64), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    ! nodes: Fortran (3, np) 列優先 -> HDF5 C [total_np][3]
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    ! Convert rank-local IDs to the concatenated HDF5 node numbering.
    call write_slab_int64_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int64), self%xfer_id)
  end subroutine phdf5_write_geom_ugrid_real128_int64

  subroutine phdf5_geom_polydata_real128(self, nodes)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: nodes(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)
  end subroutine phdf5_geom_polydata_real128


  !====================================================================
  ! write_point_data/write_cell_data
  !====================================================================
  subroutine phdf5_point_1d_int8(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int8_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine phdf5_point_1d_int8

  subroutine phdf5_cell_1d_int8(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_1d_int8: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int8_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine phdf5_cell_1d_int8

  subroutine phdf5_point_2d_int8(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int8_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine phdf5_point_2d_int8

  subroutine phdf5_cell_2d_int8(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_2d_int8: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int8_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine phdf5_cell_2d_int8

  subroutine phdf5_point_1d_int16(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int16_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine phdf5_point_1d_int16

  subroutine phdf5_cell_1d_int16(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_1d_int16: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int16_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine phdf5_cell_1d_int16

  subroutine phdf5_point_2d_int16(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int16_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine phdf5_point_2d_int16

  subroutine phdf5_cell_2d_int16(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_2d_int16: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int16_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine phdf5_cell_2d_int16

  subroutine phdf5_point_1d_int32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int32_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine phdf5_point_1d_int32

  subroutine phdf5_cell_1d_int32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_1d_int32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int32_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine phdf5_cell_1d_int32

  subroutine phdf5_point_2d_int32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int32_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine phdf5_point_2d_int32

  subroutine phdf5_cell_2d_int32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_2d_int32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int32_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine phdf5_cell_2d_int32

  subroutine phdf5_point_1d_int64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int64_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine phdf5_point_1d_int64

  subroutine phdf5_cell_1d_int64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_1d_int64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int64_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine phdf5_cell_1d_int64

  subroutine phdf5_point_2d_int64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int64_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine phdf5_point_2d_int64

  subroutine phdf5_cell_2d_int64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_2d_int64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int64_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine phdf5_cell_2d_int64

  subroutine phdf5_point_1d_real32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real32_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine phdf5_point_1d_real32

  subroutine phdf5_cell_1d_real32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_1d_real32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real32_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine phdf5_cell_1d_real32

  subroutine phdf5_point_2d_real32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real32_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine phdf5_point_2d_real32

  subroutine phdf5_cell_2d_real32(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_2d_real32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real32_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine phdf5_cell_2d_real32

  subroutine phdf5_point_1d_real64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real64_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine phdf5_point_1d_real64

  subroutine phdf5_cell_1d_real64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_1d_real64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real64_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine phdf5_cell_1d_real64

  subroutine phdf5_point_2d_real64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real64_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine phdf5_point_2d_real64

  subroutine phdf5_cell_2d_real64(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_2d_real64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real64_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine phdf5_cell_2d_real64

  subroutine phdf5_point_1d_real128(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real128_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine phdf5_point_1d_real128

  subroutine phdf5_cell_1d_real128(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_1d_real128: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real128_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine phdf5_cell_1d_real128

  subroutine phdf5_point_2d_real128(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real128_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine phdf5_point_2d_real128

  subroutine phdf5_cell_2d_real128(self, data, field_name)
    class(t_phdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR phdf5_cell_2d_real128: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real128_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine phdf5_cell_2d_real128


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
  !
  ! This helper intentionally creates fixed-size datasets to preserve the
  ! current visualization HDF5 layout.  A future time-series/misc writer based on
  ! H5S_UNLIMITED should use a separate create/extend path.
  !====================================================================
  subroutine write_slab_int8_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int8), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int8, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int8_1d_

  subroutine write_slab_int8_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int8), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int8, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int8_2d_

  subroutine write_slab_int16_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int16), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int16, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int16_1d_

  subroutine write_slab_int16_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int16), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int16, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int16_2d_

  subroutine write_slab_int32_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int32), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int32, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int32_1d_

  subroutine write_slab_int32_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int32), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int32, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int32_2d_

  subroutine write_slab_int64_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int64), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int64, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int64_1d_

  subroutine write_slab_int64_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int64), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int64, H5_integer_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int64_2d_

  subroutine write_slab_real32_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    real(real32), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real32, H5_real_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real32_1d_

  subroutine write_slab_real32_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    real(real32), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real32, H5_real_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real32_2d_

  subroutine write_slab_real64_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    real(real64), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real64, H5_real_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real64_1d_

  subroutine write_slab_real64_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    real(real64), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real64, H5_real_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real64_2d_

  subroutine write_slab_real128_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    real(real128), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real128, H5_real_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real128_1d_

  subroutine write_slab_real128_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    real(real128), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real128, H5_real_KIND)

    ! Assign file dataspace dimensions
    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real128_2d_


  subroutine write_field_metadata_(gid, field_name, ncomp)
    integer(HID_T), intent(in) :: gid
    character(len=*), intent(in) :: field_name
    integer, intent(in) :: ncomp
    integer(HID_T) :: did
    integer :: hdferr
    character(len=16) :: attribute_type

    select case (ncomp)
    case (1)
      attribute_type = 'Scalar'
    case (3)
      attribute_type = 'Vector'
    case (6)
      attribute_type = 'Tensor6'
    case (9)
      attribute_type = 'Tensor'
    case default
      error stop "[h5fortran/visualization] ncomp must be 1, 3, 6, or 9"
    end select

    call h5dopen_f(gid, trim(field_name), did, hdferr)
    if (hdferr /= 0) error stop "[h5fortran/visualization] cannot open field dataset"
    call write_string_attribute_(did, 'attribute_type', trim(attribute_type))
    call h5dclose_f(did, hdferr)
  end subroutine write_field_metadata_

  subroutine write_string_attribute_(obj_id, name, value)
    integer(HID_T), intent(in) :: obj_id
    character(len=*), intent(in) :: name, value
    integer(HID_T) :: aid, sid, tid
    integer(HSIZE_T) :: dims(1)
    integer(SIZE_T) :: value_len
    integer :: hdferr

    dims = [1_HSIZE_T]
    value_len = max(1_SIZE_T, int(len_trim(value), SIZE_T))
    call h5tcopy_f(H5T_FORTRAN_S1, tid, hdferr)
    call h5tset_size_f(tid, value_len, hdferr)
    call h5screate_f(H5S_SCALAR_F, sid, hdferr)
    call h5acreate_f(obj_id, trim(name), tid, sid, aid, hdferr)
    call h5awrite_f(aid, tid, value, dims, hdferr)
    call h5aclose_f(aid, hdferr)
    call h5sclose_f(sid, hdferr)
    call h5tclose_f(tid, hdferr)
  end subroutine write_string_attribute_

  subroutine write_int32_attribute_(obj_id, name, value)
    integer(HID_T), intent(in) :: obj_id
    character(len=*), intent(in) :: name
    integer(int32), intent(in) :: value
    integer(HID_T) :: aid, sid, tid
    integer(HSIZE_T) :: dims(1)
    integer :: hdferr

    dims = [1_HSIZE_T]
    tid = h5kind_to_type(int32, H5_INTEGER_KIND)
    call h5screate_f(H5S_SCALAR_F, sid, hdferr)
    call h5acreate_f(obj_id, trim(name), tid, sid, aid, hdferr)
    call h5awrite_f(aid, tid, value, dims, hdferr)
    call h5aclose_f(aid, hdferr)
    call h5sclose_f(sid, hdferr)
  end subroutine write_int32_attribute_

  subroutine write_real64_attribute_(obj_id, name, value)
    integer(HID_T), intent(in) :: obj_id
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value
    integer(HID_T) :: aid, sid, tid
    integer(HSIZE_T) :: dims(1)
    integer :: hdferr

    dims = [1_HSIZE_T]
    tid = h5kind_to_type(real64, H5_REAL_KIND)
    call h5screate_f(H5S_SCALAR_F, sid, hdferr)
    call h5acreate_f(obj_id, trim(name), tid, sid, aid, hdferr)
    call h5awrite_f(aid, tid, value, dims, hdferr)
    call h5aclose_f(aid, hdferr)
    call h5sclose_f(sid, hdferr)
  end subroutine write_real64_attribute_

end module h5fort_parallel_visualization
