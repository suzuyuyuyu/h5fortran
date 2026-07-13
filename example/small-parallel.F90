program small_parallel
  use h5fort
  use mpi
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  type(t_h5fort_parallel) :: file
  integer :: ierr, rank
  real(real64) :: local_values(2)
  real(real64), allocatable :: restored(:)

  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
  local_values = real([2 * rank + 1, 2 * rank + 2], real64)
  file%f_name = "small-parallel.h5"

  call file%open(H5FORTRAN_FORCE_WRITE)
  call file%write("/values", local_values)
  if (file%hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  call file%close()

  call file%open(H5FORTRAN_READ_ONLY)
  call file%read("/values", restored)
  if (file%hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  call file%close()

  print '(a,i0,a,*(f4.0,1x))', "rank ", rank, ": ", restored
  call MPI_Finalize(ierr)
end program small_parallel
