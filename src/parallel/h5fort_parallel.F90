module h5fort_parallel
  use h5fort_parallel_write
  use h5fort_parallel_read
  use h5fort_parallel_read_fixed
  use h5fort_parallel_hdf5_xdmf
  implicit none
  private

  public :: h5fort_pwrite
  public :: h5fort_pread
  public :: h5fort_pread_fixed

  public :: t_h5fort_parallel

  public :: t_phdf5_writer

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
  end interface h5fort_pread_fixed

  type :: t_h5fort_parallel
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
  end type t_h5fort_parallel


contains

end module h5fort_parallel
