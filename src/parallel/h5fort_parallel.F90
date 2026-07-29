! DO NOT EDIT — generated from src/fypp/parallel/h5fort_parallel.fypp
! To regenerate: src/fypp/generate_fypp.sh

!==============================================================================
! Module: h5fort_parallel_write
!
! 概要:
!   HDF5ファイルへのデータセット読み書きを行う汎用手続きを提供するモジュール。
!   中間グループはhdf5_writeが自動生成する。
!
!   対応する配列ランク: scalar, 1D, 2D, 3D, 4D (allocatable および固定長)
!   対応する型        : real(real64), real(real32), integer(int32), logical (int32で保存), character (スカラーのみ)
!   属性の書き込み   : hdf5_write_attr(file_id, path, [t_hdf5_attr("name","val"), ...], hdferr)
!                      hdf5_write の attrs=[ ... ] optional 引数でも同時指定可
!                      hdf5_write の units="..." optional 引数で単位を直接指定可
!
! 使用例 (OOP):
!   type(t_h5fort_parallel) :: h5
!   h5%f_name = "output.h5"
!   call h5%open(mode=H5FORTRAN_FORCE_WRITE)
!   call h5%write("/dataset", data)
!   call h5%close()
!
! 依存:
!   HDF5 Fortran API (hdf5モジュール), iso_fortran_env
!==============================================================================
module h5fort_parallel
  use h5fort_parallel_write
  use h5fort_parallel_read
  use h5fort_parallel_read_fixed
  use h5fort_parallel_visualization
  use hdf5
  use mpi
  use, intrinsic :: iso_fortran_env
  implicit none
  private

  integer, parameter :: H5FORTRAN_FORCE_WRITE = 1
  integer, parameter :: H5FORTRAN_READ_ONLY = 2

  public :: h5fort_pwrite
  public :: h5fort_pread
  public :: h5fort_pread_fixed

  public :: t_h5fort_parallel

  public :: t_phdf5_writer
  public :: H5FORTRAN_FORCE_WRITE, H5FORTRAN_READ_ONLY

  interface h5fort_pwrite
    module procedure h5fort_write_r64_0d, h5fort_write_r64_1d, h5fort_write_r64_2d, h5fort_write_r64_3d, h5fort_write_r64_4d
    module procedure h5fort_write_r32_0d, h5fort_write_r32_1d, h5fort_write_r32_2d, h5fort_write_r32_3d, h5fort_write_r32_4d
    module procedure h5fort_write_i32_0d, h5fort_write_i32_1d, h5fort_write_i32_2d, h5fort_write_i32_3d, h5fort_write_i32_4d
    module procedure h5fort_write_str_0d
    module procedure h5fort_write_lgc_0d, h5fort_write_lgc_1d, h5fort_write_lgc_2d, h5fort_write_lgc_3d, h5fort_write_lgc_4d
  end interface h5fort_pwrite

  interface h5fort_pread
    module procedure h5fort_read_r64_0d, h5fort_read_r64_1d, h5fort_read_r64_2d, h5fort_read_r64_3d, h5fort_read_r64_4d
    module procedure h5fort_read_r32_0d, h5fort_read_r32_1d, h5fort_read_r32_2d, h5fort_read_r32_3d, h5fort_read_r32_4d
    module procedure h5fort_read_i32_0d, h5fort_read_i32_1d, h5fort_read_i32_2d, h5fort_read_i32_3d, h5fort_read_i32_4d
    module procedure h5fort_read_str_0d
    module procedure h5fort_read_lgc_0d, h5fort_read_lgc_1d, h5fort_read_lgc_2d, h5fort_read_lgc_3d, h5fort_read_lgc_4d
  end interface h5fort_pread

  interface h5fort_pread_fixed
    module procedure h5fort_read_r64_1d_fixed, h5fort_read_r64_2d_fixed, h5fort_read_r64_3d_fixed, h5fort_read_r64_4d_fixed
    module procedure h5fort_read_r32_1d_fixed, h5fort_read_r32_2d_fixed, h5fort_read_r32_3d_fixed, h5fort_read_r32_4d_fixed
    module procedure h5fort_read_i32_1d_fixed, h5fort_read_i32_2d_fixed, h5fort_read_i32_3d_fixed, h5fort_read_i32_4d_fixed
    module procedure h5fort_read_lgc_1d_fixed, h5fort_read_lgc_2d_fixed, h5fort_read_lgc_3d_fixed, h5fort_read_lgc_4d_fixed
  end interface h5fort_pread_fixed

  type :: t_h5fort_parallel
    character(len=:), allocatable :: f_name
    integer(hid_t) :: file_id = -1
    integer :: hdferr
  contains
    procedure :: open  => h5fort_parallel_open
    procedure :: close => h5fort_parallel_close
    ! write PASS wrappers
    procedure, private :: write_r64_0d => h5fort_parallel_write_r64_0d
    procedure, private :: write_r64_1d => h5fort_parallel_write_r64_1d
    procedure, private :: write_r64_2d => h5fort_parallel_write_r64_2d
    procedure, private :: write_r64_3d => h5fort_parallel_write_r64_3d
    procedure, private :: write_r64_4d => h5fort_parallel_write_r64_4d
    procedure, private :: write_r32_0d => h5fort_parallel_write_r32_0d
    procedure, private :: write_r32_1d => h5fort_parallel_write_r32_1d
    procedure, private :: write_r32_2d => h5fort_parallel_write_r32_2d
    procedure, private :: write_r32_3d => h5fort_parallel_write_r32_3d
    procedure, private :: write_r32_4d => h5fort_parallel_write_r32_4d
    procedure, private :: write_i32_0d => h5fort_parallel_write_i32_0d
    procedure, private :: write_i32_1d => h5fort_parallel_write_i32_1d
    procedure, private :: write_i32_2d => h5fort_parallel_write_i32_2d
    procedure, private :: write_i32_3d => h5fort_parallel_write_i32_3d
    procedure, private :: write_i32_4d => h5fort_parallel_write_i32_4d
    procedure, private :: write_str_0d => h5fort_parallel_write_str_0d
    procedure, private :: write_lgc_0d => h5fort_parallel_write_lgc_0d
    procedure, private :: write_lgc_1d => h5fort_parallel_write_lgc_1d
    procedure, private :: write_lgc_2d => h5fort_parallel_write_lgc_2d
    procedure, private :: write_lgc_3d => h5fort_parallel_write_lgc_3d
    procedure, private :: write_lgc_4d => h5fort_parallel_write_lgc_4d
    generic, public :: write => &
      write_r64_0d, &
      write_r64_1d, &
      write_r64_2d, &
      write_r64_3d, &
      write_r64_4d, &
      write_r32_0d, &
      write_r32_1d, &
      write_r32_2d, &
      write_r32_3d, &
      write_r32_4d, &
      write_i32_0d, &
      write_i32_1d, &
      write_i32_2d, &
      write_i32_3d, &
      write_i32_4d, &
      write_str_0d, &
      write_lgc_0d, &
      write_lgc_1d, &
      write_lgc_2d, &
      write_lgc_3d, &
      write_lgc_4d
    ! read PASS wrappers
    procedure, private :: read_r64_0d => h5fort_parallel_read_r64_0d
    procedure, private :: read_r64_1d => h5fort_parallel_read_r64_1d
    procedure, private :: read_r64_2d => h5fort_parallel_read_r64_2d
    procedure, private :: read_r64_3d => h5fort_parallel_read_r64_3d
    procedure, private :: read_r64_4d => h5fort_parallel_read_r64_4d
    procedure, private :: read_r32_0d => h5fort_parallel_read_r32_0d
    procedure, private :: read_r32_1d => h5fort_parallel_read_r32_1d
    procedure, private :: read_r32_2d => h5fort_parallel_read_r32_2d
    procedure, private :: read_r32_3d => h5fort_parallel_read_r32_3d
    procedure, private :: read_r32_4d => h5fort_parallel_read_r32_4d
    procedure, private :: read_i32_0d => h5fort_parallel_read_i32_0d
    procedure, private :: read_i32_1d => h5fort_parallel_read_i32_1d
    procedure, private :: read_i32_2d => h5fort_parallel_read_i32_2d
    procedure, private :: read_i32_3d => h5fort_parallel_read_i32_3d
    procedure, private :: read_i32_4d => h5fort_parallel_read_i32_4d
    procedure, private :: read_str_0d => h5fort_parallel_read_str_0d
    procedure, private :: read_lgc_0d => h5fort_parallel_read_lgc_0d
    procedure, private :: read_lgc_1d => h5fort_parallel_read_lgc_1d
    procedure, private :: read_lgc_2d => h5fort_parallel_read_lgc_2d
    procedure, private :: read_lgc_3d => h5fort_parallel_read_lgc_3d
    procedure, private :: read_lgc_4d => h5fort_parallel_read_lgc_4d
    generic, public :: read => &
      read_r64_0d, &
      read_r64_1d, &
      read_r64_2d, &
      read_r64_3d, &
      read_r64_4d, &
      read_r32_0d, &
      read_r32_1d, &
      read_r32_2d, &
      read_r32_3d, &
      read_r32_4d, &
      read_i32_0d, &
      read_i32_1d, &
      read_i32_2d, &
      read_i32_3d, &
      read_i32_4d, &
      read_str_0d, &
      read_lgc_0d, &
      read_lgc_1d, &
      read_lgc_2d, &
      read_lgc_3d, &
      read_lgc_4d
    ! read_fixed PASS wrappers
    procedure, private :: read_r64_1d_fixed => h5fort_parallel_read_r64_1d_fixed
    procedure, private :: read_r64_2d_fixed => h5fort_parallel_read_r64_2d_fixed
    procedure, private :: read_r64_3d_fixed => h5fort_parallel_read_r64_3d_fixed
    procedure, private :: read_r64_4d_fixed => h5fort_parallel_read_r64_4d_fixed
    procedure, private :: read_r32_1d_fixed => h5fort_parallel_read_r32_1d_fixed
    procedure, private :: read_r32_2d_fixed => h5fort_parallel_read_r32_2d_fixed
    procedure, private :: read_r32_3d_fixed => h5fort_parallel_read_r32_3d_fixed
    procedure, private :: read_r32_4d_fixed => h5fort_parallel_read_r32_4d_fixed
    procedure, private :: read_i32_1d_fixed => h5fort_parallel_read_i32_1d_fixed
    procedure, private :: read_i32_2d_fixed => h5fort_parallel_read_i32_2d_fixed
    procedure, private :: read_i32_3d_fixed => h5fort_parallel_read_i32_3d_fixed
    procedure, private :: read_i32_4d_fixed => h5fort_parallel_read_i32_4d_fixed
    procedure, private :: read_lgc_1d_fixed => h5fort_parallel_read_lgc_1d_fixed
    procedure, private :: read_lgc_2d_fixed => h5fort_parallel_read_lgc_2d_fixed
    procedure, private :: read_lgc_3d_fixed => h5fort_parallel_read_lgc_3d_fixed
    procedure, private :: read_lgc_4d_fixed => h5fort_parallel_read_lgc_4d_fixed
    generic, public :: read_fixed => &
      read_r64_1d_fixed, &
      read_r64_2d_fixed, &
      read_r64_3d_fixed, &
      read_r64_4d_fixed, &
      read_r32_1d_fixed, &
      read_r32_2d_fixed, &
      read_r32_3d_fixed, &
      read_r32_4d_fixed, &
      read_i32_1d_fixed, &
      read_i32_2d_fixed, &
      read_i32_3d_fixed, &
      read_i32_4d_fixed, &
      read_lgc_1d_fixed, &
      read_lgc_2d_fixed, &
      read_lgc_3d_fixed, &
      read_lgc_4d_fixed
  end type t_h5fort_parallel


contains

  !============================================================================
  ! open: MPI-IO でファイルを開く
  !   mode=H5FORTRAN_FORCE_WRITE → 新規作成（既存ファイルは上書き）
  !   mode 省略                  → 既存ファイルを読み書きモードで開く
  !============================================================================
  subroutine h5fort_parallel_open(self, mode)
    class(t_h5fort_parallel), intent(inout) :: self
    integer, intent(in), optional :: mode
    integer :: mode_
    integer(hid_t) :: fapl_id
    integer :: err_local

    self%hdferr = 0
    if (.not. allocated(self%f_name)) then
      self%hdferr = -1
      return
    end if
    if (len_trim(self%f_name) == 0 .or. self%file_id >= 0_hid_t) then
      self%hdferr = -1
      return
    end if
    mode_ = 0
    if (present(mode)) mode_ = mode

    call h5pcreate_f(H5P_FILE_ACCESS_F, fapl_id, self%hdferr)
    if (self%hdferr /= 0) return
    call h5pset_fapl_mpio_f(fapl_id, MPI_COMM_WORLD, MPI_INFO_NULL, self%hdferr)
    if (self%hdferr /= 0) then
      call h5pclose_f(fapl_id, err_local)
      return
    end if

    if (mode_ == H5FORTRAN_FORCE_WRITE) then
      call h5fcreate_f(self%f_name, H5F_ACC_TRUNC_F, self%file_id, self%hdferr, access_prp=fapl_id)
    else if (mode_ == H5FORTRAN_READ_ONLY) then
      call h5fopen_f(self%f_name, H5F_ACC_RDONLY_F, self%file_id, self%hdferr, access_prp=fapl_id)
    else
      call h5fopen_f(self%f_name, H5F_ACC_RDWR_F, self%file_id, self%hdferr, access_prp=fapl_id)
    end if
    call h5pclose_f(fapl_id, err_local)
    if (self%hdferr == 0) self%hdferr = err_local
  end subroutine h5fort_parallel_open

  !============================================================================
  ! close: ファイルを閉じる
  !============================================================================
  subroutine h5fort_parallel_close(self)
    class(t_h5fort_parallel), intent(inout) :: self
    self%hdferr = 0
    if (self%file_id < 0_hid_t) then
      self%hdferr = -1
    else
      call h5fclose_f(self%file_id, self%hdferr)
      if (self%hdferr == 0) self%file_id = -1_hid_t
    end if
  end subroutine h5fort_parallel_close

  !============================================================================
  ! write PASS wrappers — real64 / real32 / int32 scalars and arrays
  !============================================================================
  subroutine h5fort_parallel_write_r64_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: scalar
    call h5fort_write_r64_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_write_r64_0d

  subroutine h5fort_parallel_write_r64_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:)
    call h5fort_write_r64_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r64_1d

  subroutine h5fort_parallel_write_r64_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:, :)
    call h5fort_write_r64_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r64_2d

  subroutine h5fort_parallel_write_r64_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:, :, :)
    call h5fort_write_r64_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r64_3d

  subroutine h5fort_parallel_write_r64_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:, :, :, :)
    call h5fort_write_r64_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r64_4d

  subroutine h5fort_parallel_write_r32_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: scalar
    call h5fort_write_r32_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_write_r32_0d

  subroutine h5fort_parallel_write_r32_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:)
    call h5fort_write_r32_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r32_1d

  subroutine h5fort_parallel_write_r32_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:, :)
    call h5fort_write_r32_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r32_2d

  subroutine h5fort_parallel_write_r32_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:, :, :)
    call h5fort_write_r32_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r32_3d

  subroutine h5fort_parallel_write_r32_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:, :, :, :)
    call h5fort_write_r32_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_r32_4d

  subroutine h5fort_parallel_write_i32_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: scalar
    call h5fort_write_i32_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_write_i32_0d

  subroutine h5fort_parallel_write_i32_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:)
    call h5fort_write_i32_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_i32_1d

  subroutine h5fort_parallel_write_i32_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:, :)
    call h5fort_write_i32_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_i32_2d

  subroutine h5fort_parallel_write_i32_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:, :, :)
    call h5fort_write_i32_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_i32_3d

  subroutine h5fort_parallel_write_i32_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:, :, :, :)
    call h5fort_write_i32_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_i32_4d


  !============================================================================
  ! write PASS wrappers — character and logical
  !============================================================================
  subroutine h5fort_parallel_write_str_0d(self, dset_path, str)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    character(len=*), intent(in) :: str
    call h5fort_write_str_0d(self%file_id, dset_path, str, self%hdferr)
  end subroutine h5fort_parallel_write_str_0d

  subroutine h5fort_parallel_write_lgc_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: scalar
    call h5fort_write_lgc_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_write_lgc_0d

  subroutine h5fort_parallel_write_lgc_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:)
    call h5fort_write_lgc_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_lgc_1d

  subroutine h5fort_parallel_write_lgc_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:, :)
    call h5fort_write_lgc_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_lgc_2d

  subroutine h5fort_parallel_write_lgc_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:, :, :)
    call h5fort_write_lgc_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_lgc_3d

  subroutine h5fort_parallel_write_lgc_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:, :, :, :)
    call h5fort_write_lgc_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_write_lgc_4d


  !============================================================================
  ! read PASS wrappers — real64 / real32 / int32 scalars and arrays
  !============================================================================
  subroutine h5fort_parallel_read_r64_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: scalar
    call h5fort_read_r64_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_read_r64_0d

  subroutine h5fort_parallel_read_r64_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:)
    call h5fort_read_r64_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_1d

  subroutine h5fort_parallel_read_r64_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :)
    call h5fort_read_r64_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_2d

  subroutine h5fort_parallel_read_r64_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_r64_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_3d

  subroutine h5fort_parallel_read_r64_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_r64_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_4d

  subroutine h5fort_parallel_read_r32_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: scalar
    call h5fort_read_r32_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_read_r32_0d

  subroutine h5fort_parallel_read_r32_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:)
    call h5fort_read_r32_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_1d

  subroutine h5fort_parallel_read_r32_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :)
    call h5fort_read_r32_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_2d

  subroutine h5fort_parallel_read_r32_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_r32_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_3d

  subroutine h5fort_parallel_read_r32_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_r32_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_4d

  subroutine h5fort_parallel_read_i32_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: scalar
    call h5fort_read_i32_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_read_i32_0d

  subroutine h5fort_parallel_read_i32_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:)
    call h5fort_read_i32_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_1d

  subroutine h5fort_parallel_read_i32_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :)
    call h5fort_read_i32_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_2d

  subroutine h5fort_parallel_read_i32_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_i32_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_3d

  subroutine h5fort_parallel_read_i32_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_i32_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_4d


  !============================================================================
  ! read PASS wrappers — character and logical
  !============================================================================
  subroutine h5fort_parallel_read_str_0d(self, dset_path, str)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    character(len=*), intent(out) :: str
    call h5fort_read_str_0d(self%file_id, dset_path, str, self%hdferr)
  end subroutine h5fort_parallel_read_str_0d

  subroutine h5fort_parallel_read_lgc_0d(self, dset_path, scalar)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: scalar
    call h5fort_read_lgc_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_0d

  subroutine h5fort_parallel_read_lgc_1d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:)
    call h5fort_read_lgc_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_1d

  subroutine h5fort_parallel_read_lgc_2d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:, :)
    call h5fort_read_lgc_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_2d

  subroutine h5fort_parallel_read_lgc_3d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_lgc_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_3d

  subroutine h5fort_parallel_read_lgc_4d(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_lgc_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_4d


  !============================================================================
  ! read_fixed PASS wrappers — real64 / real32 / int32 (1D–4D)
  !============================================================================
  subroutine h5fort_parallel_read_r64_1d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:)
    call h5fort_read_r64_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_1d_fixed

  subroutine h5fort_parallel_read_r64_2d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :)
    call h5fort_read_r64_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_2d_fixed

  subroutine h5fort_parallel_read_r64_3d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :, :)
    call h5fort_read_r64_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_3d_fixed

  subroutine h5fort_parallel_read_r64_4d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :, :, :)
    call h5fort_read_r64_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r64_4d_fixed

  subroutine h5fort_parallel_read_r32_1d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:)
    call h5fort_read_r32_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_1d_fixed

  subroutine h5fort_parallel_read_r32_2d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :)
    call h5fort_read_r32_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_2d_fixed

  subroutine h5fort_parallel_read_r32_3d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :, :)
    call h5fort_read_r32_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_3d_fixed

  subroutine h5fort_parallel_read_r32_4d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :, :, :)
    call h5fort_read_r32_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_r32_4d_fixed

  subroutine h5fort_parallel_read_i32_1d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:)
    call h5fort_read_i32_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_1d_fixed

  subroutine h5fort_parallel_read_i32_2d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :)
    call h5fort_read_i32_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_2d_fixed

  subroutine h5fort_parallel_read_i32_3d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :, :)
    call h5fort_read_i32_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_3d_fixed

  subroutine h5fort_parallel_read_i32_4d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :, :, :)
    call h5fort_read_i32_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_i32_4d_fixed


  subroutine h5fort_parallel_read_lgc_1d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:)
    call h5fort_read_lgc_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_1d_fixed

  subroutine h5fort_parallel_read_lgc_2d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :)
    call h5fort_read_lgc_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_2d_fixed

  subroutine h5fort_parallel_read_lgc_3d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :, :)
    call h5fort_read_lgc_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_3d_fixed

  subroutine h5fort_parallel_read_lgc_4d_fixed(self, dset_path, array)
    class(t_h5fort_parallel), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :, :, :)
    call h5fort_read_lgc_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_parallel_read_lgc_4d_fixed


end module h5fort_parallel
