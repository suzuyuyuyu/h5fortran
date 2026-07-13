program small_serial
  use h5fort
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  type(t_h5fort_serial) :: file
  real(real64) :: values(3)
  real(real64), allocatable :: restored(:)

  values = [1.0_real64, 2.0_real64, 3.0_real64]
  file%f_name = "small-serial.h5"

  call file%open(H5FORTRAN_FORCE_WRITE)
  if (file%hdferr /= 0) error stop "open failed"
  call file%write("/measurements/value", values, units="m/s")
  if (file%hdferr /= 0) error stop "write failed"
  call file%close()

  call file%open(H5FORTRAN_READ_ONLY)
  call file%read("/measurements/value", restored)
  if (file%hdferr /= 0) error stop "read failed"
  call file%close()

  print '(a,*(f5.1,1x))', "restored: ", restored
end program small_serial
