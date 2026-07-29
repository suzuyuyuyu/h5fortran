program serial
  use hdf5
  use h5fort, only: h5fort_swrite
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  integer(hid_t) :: file_id
  integer :: hdferr
  real(real64) :: values(3) = [1.0_real64, 2.0_real64, 3.0_real64]

  call h5open_f(hdferr)
  if (hdferr /= 0) error stop "h5open_f failed"
  call h5fcreate_f("serial.h5", H5F_ACC_TRUNC_F, file_id, hdferr)
  if (hdferr /= 0) error stop "h5fcreate_f failed"

  call h5fort_swrite(file_id, "/values", values, hdferr)
  if (hdferr /= 0) error stop "h5fort_swrite failed"

  call h5fclose_f(file_id, hdferr)
  if (hdferr /= 0) error stop "h5fclose_f failed"
  call h5close_f(hdferr)
  if (hdferr /= 0) error stop "h5close_f failed"
end program serial
