! DO NOT EDIT — generated from src/fypp/serial/h5fort_serial.fypp
! To regenerate: src/fypp/generate_fypp.sh

!==============================================================================
! Module: h5fort_serial_write
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
!   type(t_h5fort_serial) :: h5
!   h5%f_name = "output.h5"
!   call h5%open(mode=H5FORTRAN_FORCE_WRITE)
!   call h5%write("/dataset", data)
!   call h5%close()
!
! 依存:
!   HDF5 Fortran API (hdf5モジュール), iso_fortran_env
!==============================================================================
module h5fort_serial
  use h5fort_serial_write
  use h5fort_serial_read
  use h5fort_serial_read_fixed
  use hdf5
  use, intrinsic :: iso_fortran_env
  implicit none
  private

  public :: h5fort_swrite
  public :: h5fort_sread
  public :: h5fort_sread_fixed
  public :: h5fort_swrite_attr

  public :: t_hdf5_attr
  public :: t_h5fort_serial

  public :: H5FORTRAN_FORCE_WRITE
  public :: H5FORTRAN_READ_ONLY

  interface h5fort_swrite
    module procedure h5fort_write_r64_0d, h5fort_write_r64_1d, h5fort_write_r64_2d, h5fort_write_r64_3d, h5fort_write_r64_4d
    module procedure h5fort_write_r32_0d, h5fort_write_r32_1d, h5fort_write_r32_2d, h5fort_write_r32_3d, h5fort_write_r32_4d
    module procedure h5fort_write_i32_0d, h5fort_write_i32_1d, h5fort_write_i32_2d, h5fort_write_i32_3d, h5fort_write_i32_4d
    module procedure h5fort_write_str_0d
    module procedure h5fort_write_lgc_0d, h5fort_write_lgc_1d, h5fort_write_lgc_2d, h5fort_write_lgc_3d, h5fort_write_lgc_4d
  end interface h5fort_swrite

  interface h5fort_sread
    module procedure h5fort_read_r64_0d, h5fort_read_r64_1d, h5fort_read_r64_2d, h5fort_read_r64_3d, h5fort_read_r64_4d
    module procedure h5fort_read_r32_0d, h5fort_read_r32_1d, h5fort_read_r32_2d, h5fort_read_r32_3d, h5fort_read_r32_4d
    module procedure h5fort_read_i32_0d, h5fort_read_i32_1d, h5fort_read_i32_2d, h5fort_read_i32_3d, h5fort_read_i32_4d
    module procedure h5fort_read_str_0d
    module procedure h5fort_read_lgc_0d, h5fort_read_lgc_1d, h5fort_read_lgc_2d, h5fort_read_lgc_3d, h5fort_read_lgc_4d
  end interface h5fort_sread

  interface h5fort_sread_fixed
    module procedure h5fort_read_r64_1d_fixed, h5fort_read_r64_2d_fixed, h5fort_read_r64_3d_fixed, h5fort_read_r64_4d_fixed
    module procedure h5fort_read_r32_1d_fixed, h5fort_read_r32_2d_fixed, h5fort_read_r32_3d_fixed, h5fort_read_r32_4d_fixed
    module procedure h5fort_read_i32_1d_fixed, h5fort_read_i32_2d_fixed, h5fort_read_i32_3d_fixed, h5fort_read_i32_4d_fixed
    module procedure h5fort_read_lgc_1d_fixed, h5fort_read_lgc_2d_fixed, h5fort_read_lgc_3d_fixed, h5fort_read_lgc_4d_fixed
  end interface h5fort_sread_fixed

  type :: t_h5fort_serial
    character(len=:), allocatable :: f_name
    integer(hid_t) :: file_id = -1
    integer :: hdferr
  contains
    procedure :: open  => h5fort_serial_open
    procedure :: close => h5fort_serial_close
    ! write PASS wrappers
    procedure, private :: write_r64_0d => h5fort_serial_write_r64_0d
    procedure, private :: write_r64_1d => h5fort_serial_write_r64_1d
    procedure, private :: write_r64_2d => h5fort_serial_write_r64_2d
    procedure, private :: write_r64_3d => h5fort_serial_write_r64_3d
    procedure, private :: write_r64_4d => h5fort_serial_write_r64_4d
    procedure, private :: write_r32_0d => h5fort_serial_write_r32_0d
    procedure, private :: write_r32_1d => h5fort_serial_write_r32_1d
    procedure, private :: write_r32_2d => h5fort_serial_write_r32_2d
    procedure, private :: write_r32_3d => h5fort_serial_write_r32_3d
    procedure, private :: write_r32_4d => h5fort_serial_write_r32_4d
    procedure, private :: write_i32_0d => h5fort_serial_write_i32_0d
    procedure, private :: write_i32_1d => h5fort_serial_write_i32_1d
    procedure, private :: write_i32_2d => h5fort_serial_write_i32_2d
    procedure, private :: write_i32_3d => h5fort_serial_write_i32_3d
    procedure, private :: write_i32_4d => h5fort_serial_write_i32_4d
    procedure, private :: write_str_0d => h5fort_serial_write_str_0d
    procedure, private :: write_lgc_0d => h5fort_serial_write_lgc_0d
    procedure, private :: write_lgc_1d => h5fort_serial_write_lgc_1d
    procedure, private :: write_lgc_2d => h5fort_serial_write_lgc_2d
    procedure, private :: write_lgc_3d => h5fort_serial_write_lgc_3d
    procedure, private :: write_lgc_4d => h5fort_serial_write_lgc_4d
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
    procedure, private :: read_r64_0d => h5fort_serial_read_r64_0d
    procedure, private :: read_r64_1d => h5fort_serial_read_r64_1d
    procedure, private :: read_r64_2d => h5fort_serial_read_r64_2d
    procedure, private :: read_r64_3d => h5fort_serial_read_r64_3d
    procedure, private :: read_r64_4d => h5fort_serial_read_r64_4d
    procedure, private :: read_r32_0d => h5fort_serial_read_r32_0d
    procedure, private :: read_r32_1d => h5fort_serial_read_r32_1d
    procedure, private :: read_r32_2d => h5fort_serial_read_r32_2d
    procedure, private :: read_r32_3d => h5fort_serial_read_r32_3d
    procedure, private :: read_r32_4d => h5fort_serial_read_r32_4d
    procedure, private :: read_i32_0d => h5fort_serial_read_i32_0d
    procedure, private :: read_i32_1d => h5fort_serial_read_i32_1d
    procedure, private :: read_i32_2d => h5fort_serial_read_i32_2d
    procedure, private :: read_i32_3d => h5fort_serial_read_i32_3d
    procedure, private :: read_i32_4d => h5fort_serial_read_i32_4d
    procedure, private :: read_str_0d => h5fort_serial_read_str_0d
    procedure, private :: read_lgc_0d => h5fort_serial_read_lgc_0d
    procedure, private :: read_lgc_1d => h5fort_serial_read_lgc_1d
    procedure, private :: read_lgc_2d => h5fort_serial_read_lgc_2d
    procedure, private :: read_lgc_3d => h5fort_serial_read_lgc_3d
    procedure, private :: read_lgc_4d => h5fort_serial_read_lgc_4d
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
    procedure, private :: read_r64_1d_fixed => h5fort_serial_read_r64_1d_fixed
    procedure, private :: read_r64_2d_fixed => h5fort_serial_read_r64_2d_fixed
    procedure, private :: read_r64_3d_fixed => h5fort_serial_read_r64_3d_fixed
    procedure, private :: read_r64_4d_fixed => h5fort_serial_read_r64_4d_fixed
    procedure, private :: read_r32_1d_fixed => h5fort_serial_read_r32_1d_fixed
    procedure, private :: read_r32_2d_fixed => h5fort_serial_read_r32_2d_fixed
    procedure, private :: read_r32_3d_fixed => h5fort_serial_read_r32_3d_fixed
    procedure, private :: read_r32_4d_fixed => h5fort_serial_read_r32_4d_fixed
    procedure, private :: read_i32_1d_fixed => h5fort_serial_read_i32_1d_fixed
    procedure, private :: read_i32_2d_fixed => h5fort_serial_read_i32_2d_fixed
    procedure, private :: read_i32_3d_fixed => h5fort_serial_read_i32_3d_fixed
    procedure, private :: read_i32_4d_fixed => h5fort_serial_read_i32_4d_fixed
    procedure, private :: read_lgc_1d_fixed => h5fort_serial_read_lgc_1d_fixed
    procedure, private :: read_lgc_2d_fixed => h5fort_serial_read_lgc_2d_fixed
    procedure, private :: read_lgc_3d_fixed => h5fort_serial_read_lgc_3d_fixed
    procedure, private :: read_lgc_4d_fixed => h5fort_serial_read_lgc_4d_fixed
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
  end type t_h5fort_serial


contains

  !============================================================================
  ! open: ファイルを開く
  !   mode=H5FORTRAN_FORCE_WRITE → 新規作成（既存ファイルは上書き）
  !   mode 省略                  → 既存ファイルを読み書きモードで開く
  !============================================================================
  subroutine h5fort_serial_open(self, mode)
    class(t_h5fort_serial), intent(inout) :: self
    integer, intent(in), optional :: mode
    integer :: mode_
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
    call h5open_f(self%hdferr)
    if (self%hdferr /= 0) return
    if (mode_ == H5FORTRAN_FORCE_WRITE) then
      call h5fcreate_f(self%f_name, H5F_ACC_TRUNC_F, self%file_id, self%hdferr)
    else if (mode_ == H5FORTRAN_READ_ONLY) then
      call h5fopen_f(self%f_name, H5F_ACC_RDONLY_F, self%file_id, self%hdferr)
    else
      call h5fopen_f(self%f_name, H5F_ACC_RDWR_F, self%file_id, self%hdferr)
    end if
  end subroutine h5fort_serial_open

  !============================================================================
  ! close: ファイルを閉じる
  !============================================================================
  subroutine h5fort_serial_close(self)
    class(t_h5fort_serial), intent(inout) :: self
    integer :: err_local
    self%hdferr = 0
    if (self%file_id < 0_hid_t) then
      self%hdferr = -1
    else
      call h5fclose_f(self%file_id, self%hdferr)
      if (self%hdferr == 0) self%file_id = -1_hid_t
    end if
    call h5close_f(err_local)
    if (self%hdferr == 0) self%hdferr = err_local
  end subroutine h5fort_serial_close

  !============================================================================
  ! write PASS wrappers — real64 / real32 / int32 scalars and arrays
  !============================================================================
  subroutine h5fort_serial_write_r64_0d(self, dset_path, scalar, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real64),         intent(in) :: scalar
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r64_0d(self%file_id, dset_path, scalar, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r64_0d

  subroutine h5fort_serial_write_r64_1d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real64),         intent(in) :: array(:)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r64_1d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r64_1d

  subroutine h5fort_serial_write_r64_2d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real64),         intent(in) :: array(:, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r64_2d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r64_2d

  subroutine h5fort_serial_write_r64_3d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real64),         intent(in) :: array(:, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r64_3d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r64_3d

  subroutine h5fort_serial_write_r64_4d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real64),         intent(in) :: array(:, :, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r64_4d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r64_4d

  subroutine h5fort_serial_write_r32_0d(self, dset_path, scalar, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real32),         intent(in) :: scalar
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r32_0d(self%file_id, dset_path, scalar, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r32_0d

  subroutine h5fort_serial_write_r32_1d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real32),         intent(in) :: array(:)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r32_1d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r32_1d

  subroutine h5fort_serial_write_r32_2d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real32),         intent(in) :: array(:, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r32_2d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r32_2d

  subroutine h5fort_serial_write_r32_3d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real32),         intent(in) :: array(:, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r32_3d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r32_3d

  subroutine h5fort_serial_write_r32_4d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    real(real32),         intent(in) :: array(:, :, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_r32_4d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_r32_4d

  subroutine h5fort_serial_write_i32_0d(self, dset_path, scalar, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    integer(int32),         intent(in) :: scalar
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_i32_0d(self%file_id, dset_path, scalar, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_i32_0d

  subroutine h5fort_serial_write_i32_1d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    integer(int32),         intent(in) :: array(:)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_i32_1d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_i32_1d

  subroutine h5fort_serial_write_i32_2d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    integer(int32),         intent(in) :: array(:, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_i32_2d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_i32_2d

  subroutine h5fort_serial_write_i32_3d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    integer(int32),         intent(in) :: array(:, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_i32_3d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_i32_3d

  subroutine h5fort_serial_write_i32_4d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    integer(int32),         intent(in) :: array(:, :, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_i32_4d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_i32_4d


  !============================================================================
  ! write PASS wrappers — character and logical
  !============================================================================
  subroutine h5fort_serial_write_str_0d(self, dset_path, str, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    character(len=*),  intent(in) :: str
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_str_0d(self%file_id, dset_path, str, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_str_0d

  subroutine h5fort_serial_write_lgc_0d(self, dset_path, scalar, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    logical,           intent(in) :: scalar
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_lgc_0d(self%file_id, dset_path, scalar, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_lgc_0d

  subroutine h5fort_serial_write_lgc_1d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    logical,           intent(in) :: array(:)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_lgc_1d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_lgc_1d

  subroutine h5fort_serial_write_lgc_2d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    logical,           intent(in) :: array(:, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_lgc_2d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_lgc_2d

  subroutine h5fort_serial_write_lgc_3d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    logical,           intent(in) :: array(:, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_lgc_3d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_lgc_3d

  subroutine h5fort_serial_write_lgc_4d(self, dset_path, array, mode, attrs, units)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),  intent(in) :: dset_path
    logical,           intent(in) :: array(:, :, :, :)
    integer,           intent(in), optional :: mode
    type(t_hdf5_attr), intent(in), optional :: attrs(:)
    character(len=*),  intent(in), optional :: units
    call h5fort_write_lgc_4d(self%file_id, dset_path, array, self%hdferr, mode, attrs, units)
  end subroutine h5fort_serial_write_lgc_4d


  !============================================================================
  ! read PASS wrappers — real64 / real32 / int32 scalars and arrays
  !============================================================================
  subroutine h5fort_serial_read_r64_0d(self, dset_path, scalar)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: scalar
    call h5fort_read_r64_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_serial_read_r64_0d

  subroutine h5fort_serial_read_r64_1d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:)
    call h5fort_read_r64_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_1d

  subroutine h5fort_serial_read_r64_2d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :)
    call h5fort_read_r64_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_2d

  subroutine h5fort_serial_read_r64_3d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_r64_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_3d

  subroutine h5fort_serial_read_r64_4d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_r64_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_4d

  subroutine h5fort_serial_read_r32_0d(self, dset_path, scalar)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: scalar
    call h5fort_read_r32_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_serial_read_r32_0d

  subroutine h5fort_serial_read_r32_1d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:)
    call h5fort_read_r32_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_1d

  subroutine h5fort_serial_read_r32_2d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :)
    call h5fort_read_r32_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_2d

  subroutine h5fort_serial_read_r32_3d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_r32_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_3d

  subroutine h5fort_serial_read_r32_4d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_r32_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_4d

  subroutine h5fort_serial_read_i32_0d(self, dset_path, scalar)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: scalar
    call h5fort_read_i32_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_serial_read_i32_0d

  subroutine h5fort_serial_read_i32_1d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:)
    call h5fort_read_i32_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_1d

  subroutine h5fort_serial_read_i32_2d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :)
    call h5fort_read_i32_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_2d

  subroutine h5fort_serial_read_i32_3d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_i32_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_3d

  subroutine h5fort_serial_read_i32_4d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_i32_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_4d


  !============================================================================
  ! read PASS wrappers — character and logical
  !============================================================================
  subroutine h5fort_serial_read_str_0d(self, dset_path, str)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),              intent(in)  :: dset_path
    character(len=:), allocatable, intent(out) :: str
    call h5fort_read_str_0d(self%file_id, dset_path, str, self%hdferr)
  end subroutine h5fort_serial_read_str_0d

  subroutine h5fort_serial_read_lgc_0d(self, dset_path, scalar)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: scalar
    call h5fort_read_lgc_0d(self%file_id, dset_path, scalar, self%hdferr)
  end subroutine h5fort_serial_read_lgc_0d

  subroutine h5fort_serial_read_lgc_1d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:)
    call h5fort_read_lgc_1d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_1d

  subroutine h5fort_serial_read_lgc_2d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:, :)
    call h5fort_read_lgc_2d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_2d

  subroutine h5fort_serial_read_lgc_3d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :)
    call h5fort_read_lgc_3d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_3d

  subroutine h5fort_serial_read_lgc_4d(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*),     intent(in)  :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :, :)
    call h5fort_read_lgc_4d(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_4d


  !============================================================================
  ! read_fixed PASS wrappers — real64 / real32 / int32 (1D–4D)
  !============================================================================
  subroutine h5fort_serial_read_r64_1d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:)
    call h5fort_read_r64_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_1d_fixed

  subroutine h5fort_serial_read_r64_2d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :)
    call h5fort_read_r64_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_2d_fixed

  subroutine h5fort_serial_read_r64_3d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :, :)
    call h5fort_read_r64_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_3d_fixed

  subroutine h5fort_serial_read_r64_4d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :, :, :)
    call h5fort_read_r64_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r64_4d_fixed

  subroutine h5fort_serial_read_r32_1d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:)
    call h5fort_read_r32_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_1d_fixed

  subroutine h5fort_serial_read_r32_2d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :)
    call h5fort_read_r32_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_2d_fixed

  subroutine h5fort_serial_read_r32_3d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :, :)
    call h5fort_read_r32_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_3d_fixed

  subroutine h5fort_serial_read_r32_4d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :, :, :)
    call h5fort_read_r32_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_r32_4d_fixed

  subroutine h5fort_serial_read_i32_1d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:)
    call h5fort_read_i32_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_1d_fixed

  subroutine h5fort_serial_read_i32_2d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :)
    call h5fort_read_i32_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_2d_fixed

  subroutine h5fort_serial_read_i32_3d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :, :)
    call h5fort_read_i32_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_3d_fixed

  subroutine h5fort_serial_read_i32_4d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :, :, :)
    call h5fort_read_i32_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_i32_4d_fixed


  subroutine h5fort_serial_read_lgc_1d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:)
    call h5fort_read_lgc_1d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_1d_fixed

  subroutine h5fort_serial_read_lgc_2d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :)
    call h5fort_read_lgc_2d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_2d_fixed

  subroutine h5fort_serial_read_lgc_3d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :, :)
    call h5fort_read_lgc_3d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_3d_fixed

  subroutine h5fort_serial_read_lgc_4d_fixed(self, dset_path, array)
    class(t_h5fort_serial), intent(inout) :: self
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :, :, :)
    call h5fort_read_lgc_4d_fixed(self%file_id, dset_path, array, self%hdferr)
  end subroutine h5fort_serial_read_lgc_4d_fixed


end module h5fort_serial
