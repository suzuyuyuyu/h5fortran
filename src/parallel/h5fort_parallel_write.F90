! DO NOT EDIT — generated from src/fypp/parallel/h5fort_parallel_write.fypp
! To regenerate: src/fypp/generate_fypp.sh

#include "h5fort_config.inc"
#include "h5fort_parallel.inc"
module h5fort_parallel_write
  use hdf5
  use mpi
  use, intrinsic :: iso_fortran_env
  implicit none
  private

  public :: h5fort_write_r64_0d, h5fort_write_r64_1d, h5fort_write_r64_2d, h5fort_write_r64_3d, h5fort_write_r64_4d
  public :: h5fort_write_r32_0d, h5fort_write_r32_1d, h5fort_write_r32_2d, h5fort_write_r32_3d, h5fort_write_r32_4d
  public :: h5fort_write_i32_0d, h5fort_write_i32_1d, h5fort_write_i32_2d, h5fort_write_i32_3d, h5fort_write_i32_4d
  public :: h5fort_write_i64_0d, h5fort_write_i64_1d, h5fort_write_i64_2d, h5fort_write_i64_3d, h5fort_write_i64_4d
  public :: h5fort_write_str_0d
  public :: h5fort_write_lgc_0d, h5fort_write_lgc_1d, h5fort_write_lgc_2d, h5fort_write_lgc_3d, h5fort_write_lgc_4d
  public :: H5FORTRAN_XFER_COLLECTIVE, H5FORTRAN_XFER_INDEPENDENT

  character(len=*), parameter :: PARTITION_DATASET_NAME = H5FORT_DSET_PARTITION_DNAME
  integer, parameter :: H5FORTRAN_XFER_COLLECTIVE = 0
  integer, parameter :: H5FORTRAN_XFER_INDEPENDENT = 1

contains

  subroutine validate_nonpartition_dims(dims, comm, hdferr)
    integer(int64), intent(in) :: dims(:)
    integer, intent(in) :: comm
    integer, intent(out) :: hdferr
    integer(int64) :: min_dims(size(dims)), max_dims(size(dims))
    integer :: mpi_err

    hdferr = 0
    call MPI_Allreduce(dims, min_dims, size(dims), MPI_INTEGER8, MPI_MIN, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS) then
      hdferr = -1
      return
    end if
    call MPI_Allreduce(dims, max_dims, size(dims), MPI_INTEGER8, MPI_MAX, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS .or. any(min_dims /= max_dims)) hdferr = -1
  end subroutine validate_nonpartition_dims

  subroutine begin_parallel_write(file_id, dset_path, nlocal, comm, transfer_mode, group_id, xfer_id, &
                                  partition_, ntotal, local_offset, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(in) :: nlocal
    integer, intent(in) :: comm, transfer_mode
    integer(hid_t), intent(out) :: group_id, xfer_id
    integer(int64), allocatable, intent(out) :: partition_(:)
    integer(int64), intent(out) :: ntotal
    integer(int64), intent(out) :: local_offset
    integer, intent(out) :: hdferr

    integer(int64), allocatable :: count_(:)
    integer :: me, nprocs, r, mpi_err, local_error, global_error

    hdferr = 0
    group_id = -1_hid_t
    xfer_id  = -1_hid_t

    call MPI_Comm_rank(comm, me, mpi_err)
    local_error = merge(0, 1, mpi_err == MPI_SUCCESS)
    call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS .or. global_error /= 0) then; hdferr = -1; return; end if
    call MPI_Comm_size(comm, nprocs, mpi_err)
    local_error = merge(0, 1, mpi_err == MPI_SUCCESS)
    call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS .or. global_error /= 0) then; hdferr = -1; return; end if

    allocate(count_(0:nprocs - 1), partition_(0:nprocs))
    call MPI_Allgather(nlocal, 1, MPI_INTEGER8, count_, 1, MPI_INTEGER8, comm, mpi_err)
    local_error = merge(0, 1, mpi_err == MPI_SUCCESS)
    call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS .or. global_error /= 0) then; hdferr = -1; return; end if

    partition_(0) = 0_int64
    do r = 0, nprocs - 1
      partition_(r + 1) = partition_(r) + count_(r)
    end do
    ntotal = partition_(nprocs)
    local_offset = partition_(me)

    call h5gcreate_f(file_id, trim(dset_path), group_id, hdferr)
    local_error = merge(0, 1, hdferr == 0)
    call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS .or. global_error /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: h5gcreate_f failed for: ", trim(dset_path)
      hdferr = -1
      call end_parallel_write(group_id, xfer_id, hdferr)
      return
    end if

    call h5pcreate_f(H5P_DATASET_XFER_F, xfer_id, hdferr)
    local_error = merge(0, 1, hdferr == 0)
    call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS .or. global_error /= 0) then
      hdferr = -1
      call end_parallel_write(group_id, xfer_id, hdferr)
      return
    end if
    if (transfer_mode == H5FORTRAN_XFER_INDEPENDENT) then
      call h5pset_dxpl_mpio_f(xfer_id, H5FD_MPIO_INDEPENDENT_F, hdferr)
    else
      call h5pset_dxpl_mpio_f(xfer_id, H5FD_MPIO_COLLECTIVE_F, hdferr)
    end if
    local_error = merge(0, 1, hdferr == 0)
    call MPI_Allreduce(local_error, global_error, 1, MPI_INTEGER, MPI_MAX, comm, mpi_err)
    if (mpi_err /= MPI_SUCCESS .or. global_error /= 0) then
      hdferr = -1
      call end_parallel_write(group_id, xfer_id, hdferr)
    end if
  end subroutine begin_parallel_write

  subroutine end_parallel_write(group_id, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, xfer_id
    integer, intent(inout) :: hdferr

    integer :: err_local

    if (xfer_id >= 0_hid_t) then
      call h5pclose_f(xfer_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
    if (group_id >= 0_hid_t) then
      call h5gclose_f(group_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
  end subroutine end_parallel_write

  subroutine write_partition(group_id, partition_, xfer_id, comm, hdferr)
    integer(hid_t), intent(in) :: group_id, xfer_id
    integer(int64), intent(in) :: partition_(0:)
    integer, intent(in) :: comm
    integer, intent(out) :: hdferr

    call write_i64_partition_dataset(group_id, trim(PARTITION_DATASET_NAME), partition_, xfer_id, comm, hdferr)
  end subroutine write_partition

  subroutine write_i64_partition_dataset(group_id, dname, array, xfer_id, comm, hdferr)
    integer(hid_t), intent(in) :: group_id, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64), intent(in) :: array(0:)
    integer, intent(in) :: comm
    integer, intent(out) :: hdferr

    integer(hid_t) :: file_space_id, mem_space_id, dset_id
    integer(hsize_t) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(hid_t) :: h5t_i64
    integer :: me, nprocs, mpi_err, err_local

    call MPI_Comm_rank(comm, me, mpi_err)
    call MPI_Comm_size(comm, nprocs, mpi_err)
    if (nprocs + 1 /= size(array)) then
      hdferr = -1
      return
    end if
    dims_f(1) = int(nprocs + 1, hsize_t)
    if (me == 0) then
      dims_m(1) = 2_hsize_t
      hstart(1) = 0_hsize_t
      hcount(1) = 2_hsize_t
    else
      dims_m(1) = 1_hsize_t
      hstart(1) = int(me + 1, hsize_t)
      hcount(1) = 1_hsize_t
    end if
    h5t_i64 = h5kind_to_type(int64, H5_INTEGER_KIND)

    call h5screate_simple_f(1, dims_f, file_space_id, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5t_i64, file_space_id, dset_id, hdferr)
    if (hdferr == 0) then
      call h5sselect_hyperslab_f(file_space_id, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      if (hdferr == 0) call h5screate_simple_f(1, dims_m, mem_space_id, hdferr)
      if (hdferr == 0 .and. me == 0) then
        call h5dwrite_f(dset_id, h5t_i64, array(0:1), dims_m, hdferr, &
          mem_space_id=mem_space_id, file_space_id=file_space_id, xfer_prp=xfer_id)
      else if (hdferr == 0) then
        call h5dwrite_f(dset_id, h5t_i64, array(me + 1:me + 1), dims_m, hdferr, &
          mem_space_id=mem_space_id, file_space_id=file_space_id, xfer_prp=xfer_id)
      end if
      if (hdferr == 0) call h5sclose_f(mem_space_id, err_local)
      call h5dclose_f(dset_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
    call h5sclose_f(file_space_id, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_i64_partition_dataset

  subroutine validate_data_partition(group_id, partition_, hdferr)
    integer(hid_t), intent(in) :: group_id
    integer(int64), intent(in) :: partition_(0:)
    integer, intent(out) :: hdferr

    integer(hid_t) :: data_id, space_id
    integer(hsize_t) :: dims(MAX_RANK), maxdims(MAX_RANK)
    integer :: rank, err_local

    hdferr = 0
    data_id = -1_hid_t
    space_id = -1_hid_t
    if (partition_(0) /= 0_int64 .or. &
        any(partition_(1:) < partition_(:ubound(partition_, 1) - 1))) then
      hdferr = -1
      return
    end if

    call h5dopen_f(group_id, "data", data_id, hdferr)
    if (hdferr == 0) call h5dget_space_f(data_id, space_id, hdferr)
    if (hdferr == 0) call h5sget_simple_extent_ndims_f(space_id, rank, hdferr)
    if (hdferr == 0) then
      if (rank >= 1) then
        call h5sget_simple_extent_dims_f(space_id, dims(1:rank), maxdims(1:rank), hdferr)
        if (hdferr >= 0) hdferr = 0
      end if
    end if
    if (hdferr == 0) then
      if (rank < 1) then
        write(error_unit, '(a)') "[h5fort/parallel/write] ERROR: data must have rank >= 1"
        hdferr = -1
      else if (int(dims(rank), int64) /= partition_(ubound(partition_, 1))) then
        write(error_unit, '(a)') "[h5fort/parallel/write] ERROR: data size and partition end differ"
        hdferr = -1
      end if
    end if
    if (space_id >= 0_hid_t) then
      call h5sclose_f(space_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
    if (data_id >= 0_hid_t) then
      call h5dclose_f(data_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
  end subroutine validate_data_partition

  !============================================================================
  ! 内部ヘルパー: write_{rank}d_{kname}
  !============================================================================
  subroutine write_1d_r64(group_id, dname, array, h5type, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real64), intent(in) :: array(:)
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(1), dims_m(1)
    integer :: err_local

    dims_f = [int(ntotal, hsize_t)]
    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_1d_slab(fsid, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_1d_r64

  subroutine write_1d_r32(group_id, dname, array, h5type, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real32), intent(in) :: array(:)
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(1), dims_m(1)
    integer :: err_local

    dims_f = [int(ntotal, hsize_t)]
    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_1d_slab(fsid, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_1d_r32

  subroutine write_1d_i32(group_id, dname, array, h5type, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int32), intent(in) :: array(:)
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(1), dims_m(1)
    integer :: err_local

    dims_f = [int(ntotal, hsize_t)]
    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_1d_slab(fsid, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_1d_i32

  subroutine write_1d_i64(group_id, dname, array, h5type, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64), intent(in) :: array(:)
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(1), dims_m(1)
    integer :: err_local

    dims_f = [int(ntotal, hsize_t)]
    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_1d_slab(fsid, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_1d_i64

  subroutine write_2d_r64(group_id, dname, array, h5type, ncomp, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real64), intent(in) :: array(:, :)
    integer(int64), intent(in) :: ncomp
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(2), dims_m(2)
    integer :: err_local

    dims_f = [int(ncomp, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_2d_slab(fsid, ncomp, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_2d_r64

  subroutine write_2d_r32(group_id, dname, array, h5type, ncomp, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real32), intent(in) :: array(:, :)
    integer(int64), intent(in) :: ncomp
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(2), dims_m(2)
    integer :: err_local

    dims_f = [int(ncomp, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_2d_slab(fsid, ncomp, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_2d_r32

  subroutine write_2d_i32(group_id, dname, array, h5type, ncomp, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int32), intent(in) :: array(:, :)
    integer(int64), intent(in) :: ncomp
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(2), dims_m(2)
    integer :: err_local

    dims_f = [int(ncomp, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_2d_slab(fsid, ncomp, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_2d_i32

  subroutine write_2d_i64(group_id, dname, array, h5type, ncomp, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64), intent(in) :: array(:, :)
    integer(int64), intent(in) :: ncomp
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(2), dims_m(2)
    integer :: err_local

    dims_f = [int(ncomp, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_2d_slab(fsid, ncomp, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_2d_i64

  subroutine write_3d_r64(group_id, dname, array, h5type, n1, n2, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real64), intent(in) :: array(:, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(3), dims_m(3)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(3, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_3d_slab(fsid, n1, n2, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_3d_r64

  subroutine write_3d_r32(group_id, dname, array, h5type, n1, n2, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real32), intent(in) :: array(:, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(3), dims_m(3)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(3, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_3d_slab(fsid, n1, n2, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_3d_r32

  subroutine write_3d_i32(group_id, dname, array, h5type, n1, n2, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int32), intent(in) :: array(:, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(3), dims_m(3)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(3, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_3d_slab(fsid, n1, n2, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_3d_i32

  subroutine write_3d_i64(group_id, dname, array, h5type, n1, n2, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64), intent(in) :: array(:, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(3), dims_m(3)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(3, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_3d_slab(fsid, n1, n2, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_3d_i64

  subroutine write_4d_r64(group_id, dname, array, h5type, n1, n2, n3, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real64), intent(in) :: array(:, :, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: n3
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(4), dims_m(4)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(n3, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(4, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_4d_slab(fsid, n1, n2, n3, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_4d_r64

  subroutine write_4d_r32(group_id, dname, array, h5type, n1, n2, n3, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    real(real32), intent(in) :: array(:, :, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: n3
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(4), dims_m(4)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(n3, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(4, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_4d_slab(fsid, n1, n2, n3, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_4d_r32

  subroutine write_4d_i32(group_id, dname, array, h5type, n1, n2, n3, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int32), intent(in) :: array(:, :, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: n3
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(4), dims_m(4)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(n3, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(4, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_4d_slab(fsid, n1, n2, n3, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_4d_i32

  subroutine write_4d_i64(group_id, dname, array, h5type, n1, n2, n3, nlocal, off, ntotal, xfer_id, hdferr)
    integer(hid_t), intent(in) :: group_id, h5type, xfer_id
    character(len=*), intent(in) :: dname
    integer(int64), intent(in) :: array(:, :, :, :)
    integer(int64), intent(in) :: n1
    integer(int64), intent(in) :: n2
    integer(int64), intent(in) :: n3
    integer(int64), intent(in) :: nlocal, off, ntotal
    integer, intent(out) :: hdferr
    integer(hid_t) :: fsid, msid, did
    integer(hsize_t) :: dims_f(4), dims_m(4)
    integer :: err_local

    dims_f = [int(n1, hsize_t), int(n2, hsize_t), int(n3, hsize_t), int(ntotal, hsize_t)]
    call h5screate_simple_f(4, dims_f, fsid, hdferr)
    if (hdferr /= 0) return
    call h5dcreate_f(group_id, trim(dname), h5type, fsid, did, hdferr)
    if (hdferr /= 0) then
      call h5sclose_f(fsid, err_local)
      return
    end if
    call select_4d_slab(fsid, n1, n2, n3, nlocal, off, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dwrite_f(did, h5type, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call h5dclose_f(did, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(fsid, err_local)
    if (hdferr == 0) hdferr = err_local
    call h5sclose_f(msid, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine write_4d_i64


  !============================================================================
  ! h5fort_write_{kname}_0d — scalar (1D に委譲)
  !============================================================================
  subroutine h5fort_write_r64_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    real(real64) :: tmp(1)
    tmp(1) = scalar
    call h5fort_write_r64_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_r64_0d

  subroutine h5fort_write_r32_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    real(real32) :: tmp(1)
    tmp(1) = scalar
    call h5fort_write_r32_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_r32_0d

  subroutine h5fort_write_i32_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32) :: tmp(1)
    tmp(1) = scalar
    call h5fort_write_i32_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_i32_0d

  subroutine h5fort_write_i64_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(in) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int64) :: tmp(1)
    tmp(1) = scalar
    call h5fort_write_i64_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_i64_0d


  !============================================================================
  ! h5fort_write_{kname}_{rank}d — 1D–4D
  !============================================================================
  subroutine h5fort_write_r64_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    nlocal = int(size(array, 1), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_1d_r64(group_id, "data", array, H5T_NATIVE_DOUBLE, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r64_1d

  subroutine h5fort_write_r64_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: ncomp
    integer(int64) :: nonpartition_dims(1)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    ncomp = int(size(array, 1), int64)
    nonpartition_dims = [ncomp]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 2), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_2d_r64(group_id, "data", array, H5T_NATIVE_DOUBLE, ncomp, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r64_2d

  subroutine h5fort_write_r64_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: nonpartition_dims(2)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    nonpartition_dims = [n1, n2]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 3), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_3d_r64(group_id, "data", array, H5T_NATIVE_DOUBLE, n1, n2, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r64_3d

  subroutine h5fort_write_r64_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), intent(in) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: n3
    integer(int64) :: nonpartition_dims(3)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    n3 = int(size(array, 3), int64)
    nonpartition_dims = [n1, n2, n3]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 4), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_4d_r64(group_id, "data", array, H5T_NATIVE_DOUBLE, n1, n2, n3, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r64_4d

  subroutine h5fort_write_r32_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    nlocal = int(size(array, 1), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_1d_r32(group_id, "data", array, H5T_NATIVE_REAL, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r32_1d

  subroutine h5fort_write_r32_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: ncomp
    integer(int64) :: nonpartition_dims(1)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    ncomp = int(size(array, 1), int64)
    nonpartition_dims = [ncomp]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 2), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_2d_r32(group_id, "data", array, H5T_NATIVE_REAL, ncomp, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r32_2d

  subroutine h5fort_write_r32_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: nonpartition_dims(2)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    nonpartition_dims = [n1, n2]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 3), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_3d_r32(group_id, "data", array, H5T_NATIVE_REAL, n1, n2, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r32_3d

  subroutine h5fort_write_r32_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), intent(in) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: n3
    integer(int64) :: nonpartition_dims(3)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    n3 = int(size(array, 3), int64)
    nonpartition_dims = [n1, n2, n3]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 4), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_4d_r32(group_id, "data", array, H5T_NATIVE_REAL, n1, n2, n3, nlocal, local_offset, ntotal, xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_r32_4d

  subroutine h5fort_write_i32_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    nlocal = int(size(array, 1), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_1d_i32(group_id, "data", array, h5kind_to_type(int32, H5_INTEGER_KIND), nlocal, local_offset, ntotal, xfer_id,&
        & hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i32_1d

  subroutine h5fort_write_i32_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: ncomp
    integer(int64) :: nonpartition_dims(1)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    ncomp = int(size(array, 1), int64)
    nonpartition_dims = [ncomp]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 2), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_2d_i32(group_id, "data", array, h5kind_to_type(int32, H5_INTEGER_KIND), ncomp, nlocal, local_offset, ntotal,&
        & xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i32_2d

  subroutine h5fort_write_i32_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: nonpartition_dims(2)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    nonpartition_dims = [n1, n2]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 3), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_3d_i32(group_id, "data", array, h5kind_to_type(int32, H5_INTEGER_KIND), n1, n2, nlocal, local_offset, ntotal,&
        & xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i32_3d

  subroutine h5fort_write_i32_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(in) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: n3
    integer(int64) :: nonpartition_dims(3)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    n3 = int(size(array, 3), int64)
    nonpartition_dims = [n1, n2, n3]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 4), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_4d_i32(group_id, "data", array, h5kind_to_type(int32, H5_INTEGER_KIND), n1, n2, n3, nlocal, local_offset, ntotal,&
        & xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i32_4d

  subroutine h5fort_write_i64_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(in) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    nlocal = int(size(array, 1), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_1d_i64(group_id, "data", array, h5kind_to_type(int64, H5_INTEGER_KIND), nlocal, local_offset, ntotal, xfer_id,&
        & hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i64_1d

  subroutine h5fort_write_i64_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(in) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: ncomp
    integer(int64) :: nonpartition_dims(1)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    ncomp = int(size(array, 1), int64)
    nonpartition_dims = [ncomp]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 2), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_2d_i64(group_id, "data", array, h5kind_to_type(int64, H5_INTEGER_KIND), ncomp, nlocal, local_offset, ntotal,&
        & xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i64_2d

  subroutine h5fort_write_i64_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(in) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: nonpartition_dims(2)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    nonpartition_dims = [n1, n2]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 3), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_3d_i64(group_id, "data", array, h5kind_to_type(int64, H5_INTEGER_KIND), n1, n2, nlocal, local_offset, ntotal,&
        & xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i64_3d

  subroutine h5fort_write_i64_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(in) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode

    integer(int64), allocatable :: partition_(:)
    integer(int64) :: n1
    integer(int64) :: n2
    integer(int64) :: n3
    integer(int64) :: nonpartition_dims(3)
    integer(int64) :: nlocal, ntotal, local_offset
    integer(hid_t) :: group_id, xfer_id
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = H5FORTRAN_XFER_COLLECTIVE
    if (present(transfer_mode)) transfer_mode_ = transfer_mode

    n1 = int(size(array, 1), int64)
    n2 = int(size(array, 2), int64)
    n3 = int(size(array, 3), int64)
    nonpartition_dims = [n1, n2, n3]
    call validate_nonpartition_dims(nonpartition_dims, comm_, hdferr)
    if (hdferr /= 0) then
      write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: non-partition dimensions differ between ranks: ", &
        trim(dset_path)
      return
    end if
    nlocal = int(size(array, 4), int64)
    call begin_parallel_write(file_id, dset_path, nlocal, comm_, transfer_mode_, group_id, xfer_id, &
                              partition_, ntotal, local_offset, hdferr)
    if (hdferr /= 0) return
    call write_4d_i64(group_id, "data", array, h5kind_to_type(int64, H5_INTEGER_KIND), n1, n2, n3, nlocal, local_offset, ntotal,&
        & xfer_id, hdferr)
    if (hdferr == 0) call validate_data_partition(group_id, partition_, hdferr)
    if (hdferr == 0) call write_partition(group_id, partition_, xfer_id, comm_, hdferr)
    call end_parallel_write(group_id, xfer_id, hdferr)
  end subroutine h5fort_write_i64_4d


  !============================================================================
  ! h5fort_write_str_0d — parallel では未実装
  !============================================================================
  subroutine h5fort_write_str_0d(file_id, dset_path, str, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    character(len=*), intent(in) :: str
    integer, intent(out) :: hdferr

    write(error_unit, '(a,a)') "[h5fort/parallel/write] ERROR: parallel string write is not implemented: ", trim(dset_path)
    hdferr = -1
  end subroutine h5fort_write_str_0d

  !============================================================================
  ! h5fort_write_lgc_{rank}d — logical (int32 として保存)
  !============================================================================
  subroutine h5fort_write_lgc_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32) :: ival

    ival = merge(1_int32, 0_int32, scalar)
    call h5fort_write_i32_0d(file_id, dset_path, ival, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_lgc_0d

  subroutine h5fort_write_lgc_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:)

    allocate(iarray(size(array,1)))
    iarray = merge(1_int32, 0_int32, array)
    call h5fort_write_i32_1d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_lgc_1d

  subroutine h5fort_write_lgc_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:, :)

    allocate(iarray(size(array,1), size(array,2)))
    iarray = merge(1_int32, 0_int32, array)
    call h5fort_write_i32_2d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_lgc_2d

  subroutine h5fort_write_lgc_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:, :, :)

    allocate(iarray(size(array,1), size(array,2), size(array,3)))
    iarray = merge(1_int32, 0_int32, array)
    call h5fort_write_i32_3d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_lgc_3d

  subroutine h5fort_write_lgc_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, intent(in) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:, :, :, :)

    allocate(iarray(size(array,1), size(array,2), size(array,3), size(array,4)))
    iarray = merge(1_int32, 0_int32, array)
    call h5fort_write_i32_4d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
  end subroutine h5fort_write_lgc_4d


  !============================================================================
  ! Helper subroutines for selecting hyperslabs and creating memory spaces.
  !============================================================================
  include "h5fort_parallel_read_slabs.inc"
end module h5fort_parallel_write
