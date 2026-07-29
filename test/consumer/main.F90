program consumer
  use hdf5, only: h5open_f, h5close_f
  use h5fort
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  type(t_h5fort_serial) :: file
  integer :: hdferr
  real(real64) :: value

  call h5open_f(hdferr)
  if (hdferr /= 0) error stop 1
  file%f_name = "consumer.h5"
  call file%open(H5FORTRAN_FORCE_WRITE)
  call file%write("/value", 1.0_real64)
  call file%close()
  if (file%hdferr /= 0) error stop 1
  call h5close_f(hdferr)
  if (hdferr /= 0) error stop 1
end program consumer
