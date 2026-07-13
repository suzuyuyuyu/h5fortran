program serial_example
  use, intrinsic :: iso_fortran_env
  use hdf5
  use h5fort
  implicit none

  integer(int32) :: hdferr
  integer(hid_t) :: h5file_id

  type(t_h5fort_serial) :: h5s

  character(len=20) :: dataset_name_int
  integer(int32) :: data_int(5)
  character(len=20) :: dataset_name_real
  real(real64), allocatable :: data_real(:)

  ! Initialize the HDF5 library
  call h5open_f(hdferr)

  ! Prepare data to write/store in the HDF5 file
  dataset_name_int = "/IntegerData"
  data_int = [1, 2, 3, 4, 5]
  dataset_name_real = "/RealData"
  allocate(data_real(5))
  data_real = [11.1, 22.2, 33.3, 44.4, 55.5]

  ! ============================================================
  ! Serial HDF5 File Writing
  ! ============================================================
  ! Create a new HDF5 file
  call h5fcreate_f("small_serial.h5", H5F_ACC_TRUNC_F, h5file_id, hdferr)

  ! Write data using the serial interface
  ! using OOP interface
  call h5s%write(h5file_id, trim(dataset_name_int), data_int, hdferr)
  call h5s%write(h5file_id, trim(dataset_name_real), data_real, hdferr)

  ! Close the HDF5 file
  call h5fclose_f(h5file_id, hdferr)


  ! ============================================================
  ! Serial HDF5 File Reading
  ! ============================================================
  ! Open the existing HDF5 file
  call h5fopen_f("small_serial.h5", H5F_ACC_RDONLY_F, h5file_id, hdferr)

  ! Read data using the serial interface
  ! using OOP interface
  block
    integer(int32) :: read_data_int(5)
    real(real64), allocatable :: read_data_real(:)

    ! For non-allocatable (fixed-size) arrays
    call h5s%read_fixed(h5file_id, trim(dataset_name_int), read_data_int, hdferr)
    ! For allocatable arrays
    call h5s%read(h5file_id, trim(dataset_name_real), read_data_real, hdferr)

    ! Print the read data
    print '(a)', "Read Integer Data:"
    print '(2x,*(g0,1x))', read_data_int

    print '(a)', "Read Real Data:"
    print '(2x,*(g0,2x))', read_data_real
  end block

  ! Finalize the HDF5 library
  call h5close_f(hdferr)

end program serial_example
