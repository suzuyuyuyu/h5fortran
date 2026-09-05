! DO NOT EDIT — generated from src/fypp/parallel/h5fort_parallel_visualization.fypp
! To regenerate: src/fypp/generate_fypp.sh

module h5fort_parallel_visualization
  use h5fort_serial_visualization, only: t_hdf5_writer
  use hdf5
  use mpi
  use, intrinsic :: iso_fortran_env, only: int64
  implicit none
  private
  public :: t_phdf5_writer

  type, extends(t_hdf5_writer) :: t_phdf5_writer
    integer, private :: comm = MPI_COMM_WORLD
  contains
    procedure :: init => phdf5_init
    procedure :: abort_writer => phdf5_abort
  end type t_phdf5_writer

contains

  subroutine phdf5_init(self)
    class(t_phdf5_writer), intent(inout) :: self
    integer :: me, nprocs, mpi_err, hdferr, iexist
    integer(int64), allocatable :: rank_np(:), rank_nc(:)
    integer(HID_T) :: fapl_id, xfer_id
    logical :: file_exists

    call MPI_Comm_rank(self%comm, me, mpi_err)
    call MPI_Comm_size(self%comm, nprocs, mpi_err)
    allocate(rank_np(0:nprocs-1), rank_nc(0:nprocs-1))
    call MPI_Allgather(self%num_points, 1, MPI_INTEGER8, rank_np, 1, MPI_INTEGER8, self%comm, mpi_err)
    call MPI_Allgather(self%num_cells, 1, MPI_INTEGER8, rank_nc, 1, MPI_INTEGER8, self%comm, mpi_err)

    call h5pcreate_f(H5P_FILE_ACCESS_F, fapl_id, hdferr)
    call h5pset_fapl_mpio_f(fapl_id, self%comm, MPI_INFO_NULL, hdferr)
    ! Collective metadata settings conflict with independent attribute writes.
    call h5pcreate_f(H5P_DATASET_XFER_F, xfer_id, hdferr)
    call h5pset_dxpl_mpio_f(xfer_id, H5FD_MPIO_COLLECTIVE_F, hdferr)

    ! One filesystem observation avoids inconsistent open/create decisions.
    iexist = 0
    if (me == 0) then
      inquire(file=trim(self%h5_filepath), exist=file_exists)
      if (file_exists) iexist = 1
    end if
    call MPI_Bcast(iexist, 1, MPI_INTEGER, 0, self%comm, mpi_err)
    call self%initialize(fapl_id, xfer_id, iexist == 1, &
      sum(rank_np), sum(rank_nc), sum(rank_np(:me-1)), sum(rank_nc(:me-1)))
    call h5pclose_f(fapl_id, hdferr)
  end subroutine phdf5_init

  subroutine phdf5_abort(self, code)
    class(t_phdf5_writer), intent(in) :: self
    integer, intent(in) :: code
    integer :: mpi_err
    call MPI_Abort(self%comm, code, mpi_err)
  end subroutine phdf5_abort

end module h5fort_parallel_visualization
