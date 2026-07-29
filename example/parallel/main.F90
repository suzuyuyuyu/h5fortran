program parallel
  use hdf5
  use h5fort, only: h5fort_pwrite
  use mpi
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  integer(hid_t) :: file_id, fapl_id
  integer :: ierr, hdferr, rank
  real(real64) :: local_values(2)

  call MPI_Init(ierr)
  call h5open_f(hdferr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
  local_values = real([2 * rank + 1, 2 * rank + 2], real64)

  call h5pcreate_f(H5P_FILE_ACCESS_F, fapl_id, hdferr)
  call h5pset_fapl_mpio_f(fapl_id, MPI_COMM_WORLD, MPI_INFO_NULL, hdferr)
  call h5fcreate_f("parallel.h5", H5F_ACC_TRUNC_F, file_id, hdferr, access_prp=fapl_id)
  call h5pclose_f(fapl_id, hdferr)
  call h5fort_pwrite(file_id, "/values", local_values, hdferr)
  if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)

  call h5fclose_f(file_id, hdferr)
  call h5close_f(hdferr)
  call MPI_Finalize(ierr)
end program parallel
