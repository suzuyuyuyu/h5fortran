program consumer
  use h5fort
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  type(t_h5fort_serial) :: file
  real(real64) :: value

  file%f_name = "consumer.h5"
  call file%open(H5FORTRAN_FORCE_WRITE)
  call file%write("/value", 1.0_real64)
  call file%close()
  if (file%hdferr /= 0) error stop 1
end program consumer
