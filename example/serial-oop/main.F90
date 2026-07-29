program small_serial
  use hdf5, only: h5open_f, h5close_f
  use h5fort
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  type(t_h5fort_serial) :: file
  integer :: hdferr
  real(real64) :: values(3)
  real(real64), allocatable :: restored(:)

  call h5open_f(hdferr)
  if (hdferr /= 0) error stop "HDF5 initialization failed"

  values = [1.0_real64, 2.0_real64, 3.0_real64]
  file%f_name = "serial-oop.h5"

  call file%open(H5FORTRAN_FORCE_WRITE)
  if (file%hdferr /= 0) error stop "open failed"
  call file%write("/measurements/value", values, units="m/s")
  if (file%hdferr /= 0) error stop "write failed"
  call file%close()

  call file%open(H5FORTRAN_READ_ONLY)
  call file%read("/measurements/value", restored)
  if (file%hdferr /= 0) error stop "read failed"
  call file%close()

  call h5close_f(hdferr)
  if (hdferr /= 0) error stop "HDF5 finalization failed"
  print '(a,*(f5.1,1x))', "restored: ", restored
end program small_serial
