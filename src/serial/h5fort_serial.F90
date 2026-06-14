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
! 使用例:
!   use h5fort_serial_write
!   real(real64), allocatable :: arr(:,:)
!   call hdf5_read (file_id, "/step-by-step/velocity", arr, hdferr)    ! 配列
!   call hdf5_write(file_id, "/step-by-step/velocity", arr, hdferr)    ! 配列
!   call hdf5_write(file_id, "/step-by-step/velocity", arr, hdferr, units="m/s")   ! 単位付き
!   call hdf5_write(file_id, "/config/nstep", nstep, hdferr)           ! スカラー
!   call hdf5_read (file_id, "/config/nstep", nstep, hdferr)           ! スカラー
!
! 依存:
!   HDF5 Fortran API (hdf5モジュール), iso_fortran_env
!==============================================================================
module h5fort_serial
  use h5fort_serial_write
  use h5fort_serial_read
  use h5fort_serial_read_fixed
  implicit none
  private

  public :: h5fort_swrite
  public :: h5fort_sread
  public :: h5fort_sread_fixed
  public :: h5fort_swrite_attr

  public :: t_hdf5_attr
  public :: t_h5fort_serial

  public :: H5FORTRAN_FORCE_WRITE

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
  end interface h5fort_sread_fixed

  type :: t_h5fort_serial
    character(len=:), allocatable :: f_name
    integer :: hdferr
  contains
    procedure, private, nopass :: write_r64_0d => h5fort_write_r64_0d
    procedure, private, nopass :: write_r64_1d => h5fort_write_r64_1d
    procedure, private, nopass :: write_r64_2d => h5fort_write_r64_2d
    procedure, private, nopass :: write_r64_3d => h5fort_write_r64_3d
    procedure, private, nopass :: write_r64_4d => h5fort_write_r64_4d
    procedure, private, nopass :: write_r32_0d => h5fort_write_r32_0d
    procedure, private, nopass :: write_r32_1d => h5fort_write_r32_1d
    procedure, private, nopass :: write_r32_2d => h5fort_write_r32_2d
    procedure, private, nopass :: write_r32_3d => h5fort_write_r32_3d
    procedure, private, nopass :: write_r32_4d => h5fort_write_r32_4d
    procedure, private, nopass :: write_i32_0d => h5fort_write_i32_0d
    procedure, private, nopass :: write_i32_1d => h5fort_write_i32_1d
    procedure, private, nopass :: write_i32_2d => h5fort_write_i32_2d
    procedure, private, nopass :: write_i32_3d => h5fort_write_i32_3d
    procedure, private, nopass :: write_i32_4d => h5fort_write_i32_4d
    procedure, private, nopass :: write_str_0d => h5fort_write_str_0d
    procedure, private, nopass :: write_lgc_0d => h5fort_write_lgc_0d
    procedure, private, nopass :: write_lgc_1d => h5fort_write_lgc_1d
    procedure, private, nopass :: write_lgc_2d => h5fort_write_lgc_2d
    procedure, private, nopass :: write_lgc_3d => h5fort_write_lgc_3d
    procedure, private, nopass :: write_lgc_4d => h5fort_write_lgc_4d
    generic, public :: write => &
      write_r64_0d, write_r64_1d, write_r64_2d, write_r64_3d, write_r64_4d, &
      write_r32_0d, write_r32_1d, write_r32_2d, write_r32_3d, write_r32_4d, &
      write_i32_0d, write_i32_1d, write_i32_2d, write_i32_3d, write_i32_4d, &
      write_str_0d, &
      write_lgc_0d, write_lgc_1d, write_lgc_2d, write_lgc_3d, write_lgc_4d
    procedure, private, nopass :: read_r64_0d => h5fort_read_r64_0d
    procedure, private, nopass :: read_r64_1d => h5fort_read_r64_1d
    procedure, private, nopass :: read_r64_2d => h5fort_read_r64_2d
    procedure, private, nopass :: read_r64_3d => h5fort_read_r64_3d
    procedure, private, nopass :: read_r64_4d => h5fort_read_r64_4d
    procedure, private, nopass :: read_r32_0d => h5fort_read_r32_0d
    procedure, private, nopass :: read_r32_1d => h5fort_read_r32_1d
    procedure, private, nopass :: read_r32_2d => h5fort_read_r32_2d
    procedure, private, nopass :: read_r32_3d => h5fort_read_r32_3d
    procedure, private, nopass :: read_r32_4d => h5fort_read_r32_4d
    procedure, private, nopass :: read_i32_0d => h5fort_read_i32_0d
    procedure, private, nopass :: read_i32_1d => h5fort_read_i32_1d
    procedure, private, nopass :: read_i32_2d => h5fort_read_i32_2d
    procedure, private, nopass :: read_i32_3d => h5fort_read_i32_3d
    procedure, private, nopass :: read_i32_4d => h5fort_read_i32_4d
    procedure, private, nopass :: read_str_0d => h5fort_read_str_0d
    procedure, private, nopass :: read_lgc_0d => h5fort_read_lgc_0d
    procedure, private, nopass :: read_lgc_1d => h5fort_read_lgc_1d
    procedure, private, nopass :: read_lgc_2d => h5fort_read_lgc_2d
    procedure, private, nopass :: read_lgc_3d => h5fort_read_lgc_3d
    procedure, private, nopass :: read_lgc_4d => h5fort_read_lgc_4d
    generic, public :: read => &
      read_r64_0d, read_r64_1d, read_r64_2d, read_r64_3d, read_r64_4d, &
      read_r32_0d, read_r32_1d, read_r32_2d, read_r32_3d, read_r32_4d, &
      read_i32_0d, read_i32_1d, read_i32_2d, read_i32_3d, read_i32_4d, &
      read_str_0d, &
      read_lgc_0d, read_lgc_1d, read_lgc_2d, read_lgc_3d, read_lgc_4d
    procedure, private, nopass :: read_r64_1d_fixed => h5fort_read_r64_1d_fixed
    procedure, private, nopass :: read_r64_2d_fixed => h5fort_read_r64_2d_fixed
    procedure, private, nopass :: read_r64_3d_fixed => h5fort_read_r64_3d_fixed
    procedure, private, nopass :: read_r64_4d_fixed => h5fort_read_r64_4d_fixed
    procedure, private, nopass :: read_r32_1d_fixed => h5fort_read_r32_1d_fixed
    procedure, private, nopass :: read_r32_2d_fixed => h5fort_read_r32_2d_fixed
    procedure, private, nopass :: read_r32_3d_fixed => h5fort_read_r32_3d_fixed
    procedure, private, nopass :: read_r32_4d_fixed => h5fort_read_r32_4d_fixed
    procedure, private, nopass :: read_i32_1d_fixed => h5fort_read_i32_1d_fixed
    procedure, private, nopass :: read_i32_2d_fixed => h5fort_read_i32_2d_fixed
    procedure, private, nopass :: read_i32_3d_fixed => h5fort_read_i32_3d_fixed
    procedure, private, nopass :: read_i32_4d_fixed => h5fort_read_i32_4d_fixed
    generic, public :: read_fixed => &
      read_r64_1d_fixed, read_r64_2d_fixed, read_r64_3d_fixed, read_r64_4d_fixed, &
      read_r32_1d_fixed, read_r32_2d_fixed, read_r32_3d_fixed, read_r32_4d_fixed, &
      read_i32_1d_fixed, read_i32_2d_fixed, read_i32_3d_fixed, read_i32_4d_fixed
  end type t_h5fort_serial


contains

end module h5fort_serial
