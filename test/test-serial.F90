program test_serial
  use hdf5
  use h5fort
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  integer :: hdferr
  integer :: i
  integer(hid_t) :: file_id
  real(real64) :: x(3, 4), x_fixed(3, 4)
  real(real64), allocatable :: x_read(:, :)

  x = reshape([(real(i, real64), i = 1, 12)], shape(x))

  call h5open_f(hdferr); call check(hdferr)
  call h5fcreate_f("test-serial.h5", H5F_ACC_TRUNC_F, file_id, hdferr); call check(hdferr)
  call h5fort_swrite(file_id, "/x", x, hdferr); call check(hdferr)
  call h5fclose_f(file_id, hdferr); call check(hdferr)

  call h5fopen_f("test-serial.h5", H5F_ACC_RDONLY_F, file_id, hdferr); call check(hdferr)
  call h5fort_sread(file_id, "/x", x_read, hdferr); call check(hdferr)
  call h5fort_sread_fixed(file_id, "/x", x_fixed, hdferr); call check(hdferr)
  call assert(all(abs(x_read - x) < 1.0e-12_real64))
  call assert(all(abs(x_fixed - x) < 1.0e-12_real64))
  call h5fclose_f(file_id, hdferr); call check(hdferr)
  call h5close_f(hdferr); call check(hdferr)

contains

  subroutine check(ierr)
    integer, intent(in) :: ierr
    if (ierr /= 0) error stop 1
  end subroutine check

  subroutine assert(ok)
    logical, intent(in) :: ok
    if (.not. ok) error stop 1
  end subroutine assert

end program test_serial
