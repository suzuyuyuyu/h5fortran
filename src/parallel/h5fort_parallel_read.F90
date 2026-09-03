! DO NOT EDIT — generated from src/fypp/parallel/h5fort_parallel_read.fypp
! To regenerate: src/fypp/generate_fypp.sh

#include "h5fort_config.inc"
#include "h5fort_parallel.inc"
module h5fort_parallel_read
  use hdf5
  use mpi
  use, intrinsic :: iso_fortran_env
  implicit none
  private

  public :: h5fort_read_r64_0d, h5fort_read_r64_1d, h5fort_read_r64_2d, h5fort_read_r64_3d, h5fort_read_r64_4d
  public :: h5fort_read_r32_0d, h5fort_read_r32_1d, h5fort_read_r32_2d, h5fort_read_r32_3d, h5fort_read_r32_4d
  public :: h5fort_read_i32_0d, h5fort_read_i32_1d, h5fort_read_i32_2d, h5fort_read_i32_3d, h5fort_read_i32_4d
  public :: h5fort_read_i64_0d, h5fort_read_i64_1d, h5fort_read_i64_2d, h5fort_read_i64_3d, h5fort_read_i64_4d
  public :: h5fort_read_str_0d
  public :: h5fort_read_lgc_0d, h5fort_read_lgc_1d, h5fort_read_lgc_2d, h5fort_read_lgc_3d, h5fort_read_lgc_4d

  character(len=*), parameter :: PARTITION_DATASET_NAME = H5FORT_DSET_PARTITION_DNAME

contains

  subroutine begin_parallel_read(file_id, dset_path, comm, transfer_mode, data_id, file_space_id, xfer_id, &
                                 nlocal, local_offset, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer, intent(in) :: comm, transfer_mode
    integer(hid_t), intent(out) :: data_id, file_space_id, xfer_id
    integer(int64), intent(out) :: nlocal, local_offset
    integer, intent(out) :: hdferr

    integer(int64), allocatable :: partition_(:)
    integer(hsize_t) :: dims(MAX_RANK), maxdims(MAX_RANK)
    integer :: me, nprocs, rank, mpi_err

    data_id       = -1_hid_t
    file_space_id = -1_hid_t
    xfer_id       = -1_hid_t
    hdferr        = 0

    call MPI_Comm_rank(comm, me, mpi_err)
    call MPI_Comm_size(comm, nprocs, mpi_err)
    if (mpi_err /= MPI_SUCCESS) then
      hdferr = -1
      return
    end if

    allocate(partition_(0:nprocs))
    call read_i64_vector(file_id, trim(dset_path)//"/"//trim(PARTITION_DATASET_NAME), partition_, hdferr)
    if (hdferr /= 0) return

    call h5dopen_f(file_id, trim(dset_path)//"/data", data_id, hdferr)
    if (hdferr /= 0) return
    call h5dget_space_f(data_id, file_space_id, hdferr)
    if (hdferr /= 0) then
      call cleanup_parallel_read_begin(data_id, file_space_id, xfer_id, hdferr)
      return
    end if
    call h5sget_simple_extent_ndims_f(file_space_id, rank, hdferr)
    if (hdferr == 0) then
      if (rank >= 1) then
        call h5sget_simple_extent_dims_f(file_space_id, dims(1:rank), maxdims(1:rank), hdferr)
        if (hdferr >= 0) hdferr = 0
      end if
    end if
    if (hdferr == 0) then
      if (partition_(0) /= 0_int64 .or. &
          any(partition_(1:) < partition_(:ubound(partition_, 1) - 1))) then
        write(error_unit, '(a)') "[h5fort/parallel/read] ERROR: partition must start at zero and be nondecreasing"
        hdferr = -1
      else if (rank < 1) then
        write(error_unit, '(a)') "[h5fort/parallel/read] ERROR: data must have rank >= 1"
        hdferr = -1
      else if (partition_(nprocs) /= int(dims(rank), int64)) then
        write(error_unit, '(a)') "[h5fort/parallel/read] ERROR: data size and partition end differ"
        hdferr = -1
      end if
    end if
    if (hdferr /= 0) then
      call cleanup_parallel_read_begin(data_id, file_space_id, xfer_id, hdferr)
      return
    end if

    local_offset = partition_(me)
    nlocal = partition_(me + 1) - partition_(me)

    call h5pcreate_f(H5P_DATASET_XFER_F, xfer_id, hdferr)
    if (hdferr == 0) then
      if (transfer_mode == 1) then
        call h5pset_dxpl_mpio_f(xfer_id, H5FD_MPIO_INDEPENDENT_F, hdferr)
      else
        call h5pset_dxpl_mpio_f(xfer_id, H5FD_MPIO_COLLECTIVE_F, hdferr)
      end if
    end if
    if (hdferr /= 0) call cleanup_parallel_read_begin(data_id, file_space_id, xfer_id, hdferr)
  end subroutine begin_parallel_read

  subroutine cleanup_parallel_read_begin(data_id, file_space_id, xfer_id, hdferr)
    integer(hid_t), intent(inout) :: data_id, file_space_id, xfer_id
    integer, intent(inout) :: hdferr
    integer :: first_error, err_local

    first_error = hdferr
    if (xfer_id >= 0_hid_t) then
      call h5pclose_f(xfer_id, err_local)
      xfer_id = -1_hid_t
    end if
    if (file_space_id >= 0_hid_t) then
      call h5sclose_f(file_space_id, err_local)
      file_space_id = -1_hid_t
    end if
    if (data_id >= 0_hid_t) then
      call h5dclose_f(data_id, err_local)
      data_id = -1_hid_t
    end if
    hdferr = first_error
  end subroutine cleanup_parallel_read_begin

  subroutine end_parallel_read(data_id, file_space_id, mem_space_id, xfer_id, hdferr)
    integer(hid_t), intent(in) :: data_id, file_space_id, mem_space_id, xfer_id
    integer, intent(inout) :: hdferr
    integer :: err_local

    if (xfer_id >= 0_hid_t) then
      call h5pclose_f(xfer_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
    if (mem_space_id >= 0_hid_t) then
      call h5sclose_f(mem_space_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
    if (file_space_id >= 0_hid_t) then
      call h5sclose_f(file_space_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
    if (data_id >= 0_hid_t) then
      call h5dclose_f(data_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
  end subroutine end_parallel_read

  subroutine read_i64_vector(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(out) :: array(0:)
    integer, intent(out) :: hdferr
    integer(hid_t) :: dset_id, space_id, h5t_i64
    integer(hsize_t) :: dims(1), file_dims(1), maxdims(1)
    integer :: rank, err_local

    dset_id = -1_hid_t
    space_id = -1_hid_t
    dims(1) = int(size(array), hsize_t)
    h5t_i64 = h5kind_to_type(int64, H5_INTEGER_KIND)
    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) return
    call h5dget_space_f(dset_id, space_id, hdferr)
    if (hdferr == 0) call h5sget_simple_extent_ndims_f(space_id, rank, hdferr)
    if (hdferr == 0) then
      if (rank == 1) then
        call h5sget_simple_extent_dims_f(space_id, file_dims, maxdims, hdferr)
        if (hdferr >= 0) hdferr = 0
      end if
    end if
    if (hdferr == 0) then
      if (rank /= 1 .or. file_dims(1) /= dims(1)) hdferr = -1
    end if
    if (hdferr == 0) call h5dread_f(dset_id, h5t_i64, array, dims, hdferr)
    if (space_id >= 0_hid_t) then
      call h5sclose_f(space_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
    if (dset_id >= 0_hid_t) then
      call h5dclose_f(dset_id, err_local)
      if (hdferr == 0) hdferr = err_local
    end if
  end subroutine read_i64_vector

  subroutine get_data_rank_dims(data_id, rank, dims, hdferr)
    integer(hid_t), intent(in) :: data_id
    integer, intent(out) :: rank
    integer(hsize_t), intent(out) :: dims(MAX_RANK)
    integer, intent(out) :: hdferr
    integer(hid_t) :: space_id
    integer(hsize_t) :: maxdims(MAX_RANK)
    integer :: err_local

    dims = 1_hsize_t
    call h5dget_space_f(data_id, space_id, hdferr)
    if (hdferr /= 0) return
    call h5sget_simple_extent_ndims_f(space_id, rank, hdferr)
    if (hdferr == 0) then
      call h5sget_simple_extent_dims_f(space_id, dims(1:rank), maxdims(1:rank), hdferr)
      if (hdferr >= 0) hdferr = 0
    end if
    call h5sclose_f(space_id, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine get_data_rank_dims

  !============================================================================
  ! h5fort_read_{kname}_0d — scalar (1D に委譲)
  !============================================================================
  subroutine h5fort_read_r64_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), intent(out) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    real(real64), allocatable :: array(:)

    call h5fort_read_r64_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      if (size(array) /= 1) then
        hdferr = -1
      else
        scalar = array(1)
      end if
    end if
  end subroutine h5fort_read_r64_0d

  subroutine h5fort_read_r32_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), intent(out) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    real(real32), allocatable :: array(:)

    call h5fort_read_r32_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      if (size(array) /= 1) then
        hdferr = -1
      else
        scalar = array(1)
      end if
    end if
  end subroutine h5fort_read_r32_0d

  subroutine h5fort_read_i32_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(out) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: array(:)

    call h5fort_read_i32_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      if (size(array) /= 1) then
        hdferr = -1
      else
        scalar = array(1)
      end if
    end if
  end subroutine h5fort_read_i32_0d

  subroutine h5fort_read_i64_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), intent(out) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int64), allocatable :: array(:)

    call h5fort_read_i64_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      if (size(array) /= 1) then
        hdferr = -1
      else
        scalar = array(1)
      end if
    end if
  end subroutine h5fort_read_i64_0d


  !============================================================================
  ! h5fort_read_{kname}_1d — 1D allocatable
  !============================================================================
  subroutine h5fort_read_r64_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer(hsize_t) :: dims_m(1)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    allocate(array(nlocal))
    call select_1d_slab(fsid, nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_1d

  subroutine h5fort_read_r32_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer(hsize_t) :: dims_m(1)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    allocate(array(nlocal))
    call select_1d_slab(fsid, nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_1d

  subroutine h5fort_read_i32_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer(hsize_t) :: dims_m(1)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    allocate(array(nlocal))
    call select_1d_slab(fsid, nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int32, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_1d

  subroutine h5fort_read_i64_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer(hsize_t) :: dims_m(1)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    allocate(array(nlocal))
    call select_1d_slab(fsid, nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int64, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i64_1d


  !============================================================================
  ! h5fort_read_{kname}_{rank}d — 2D–4D allocatable
  !============================================================================
  subroutine h5fort_read_r64_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(2)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 2) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), nlocal))
    if (hdferr == 0) call select_2d_slab(fsid, int(dims(1), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_2d

  subroutine h5fort_read_r64_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(3)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 3) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), nlocal))
    if (hdferr == 0) call select_3d_slab(fsid, int(dims(1), int64), int(dims(2), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_3d

  subroutine h5fort_read_r64_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(4)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 4) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), dims(3), nlocal))
    if (hdferr == 0) call select_4d_slab(fsid, int(dims(1), int64), int(dims(2), int64), int(dims(3), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_4d

  subroutine h5fort_read_r32_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(2)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 2) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), nlocal))
    if (hdferr == 0) call select_2d_slab(fsid, int(dims(1), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_2d

  subroutine h5fort_read_r32_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(3)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 3) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), nlocal))
    if (hdferr == 0) call select_3d_slab(fsid, int(dims(1), int64), int(dims(2), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_3d

  subroutine h5fort_read_r32_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(4)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 4) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), dims(3), nlocal))
    if (hdferr == 0) call select_4d_slab(fsid, int(dims(1), int64), int(dims(2), int64), int(dims(3), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid,&
        & xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_4d

  subroutine h5fort_read_i32_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(2)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 2) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), nlocal))
    if (hdferr == 0) call select_2d_slab(fsid, int(dims(1), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int32, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_2d

  subroutine h5fort_read_i32_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(3)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 3) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), nlocal))
    if (hdferr == 0) call select_3d_slab(fsid, int(dims(1), int64), int(dims(2), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int32, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_3d

  subroutine h5fort_read_i32_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(4)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 4) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), dims(3), nlocal))
    if (hdferr == 0) call select_4d_slab(fsid, int(dims(1), int64), int(dims(2), int64), int(dims(3), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int32, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_4d

  subroutine h5fort_read_i64_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(2)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 2) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), nlocal))
    if (hdferr == 0) call select_2d_slab(fsid, int(dims(1), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int64, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i64_2d

  subroutine h5fort_read_i64_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(3)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 3) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), nlocal))
    if (hdferr == 0) call select_3d_slab(fsid, int(dims(1), int64), int(dims(2), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int64, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i64_3d

  subroutine h5fort_read_i64_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int64), allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64) :: nlocal, local_offset
    integer :: rank_
    integer(hsize_t) :: dims(MAX_RANK), dims_m(4)
    integer :: comm_, transfer_mode_

    comm_ = MPI_COMM_WORLD; if (present(comm)) comm_ = comm
    transfer_mode_ = 0; if (present(transfer_mode)) transfer_mode_ = transfer_mode
    msid = -1_hid_t
    call begin_parallel_read(file_id, dset_path, comm_, transfer_mode_, data_id, fsid, xfer_id, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank_, dims, hdferr)
    if (hdferr == 0 .and. rank_ /= 4) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), dims(3), nlocal))
    if (hdferr == 0) call select_4d_slab(fsid, int(dims(1), int64), int(dims(2), int64), int(dims(3), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5kind_to_type(int64, H5_INTEGER_KIND), array, dims_m, hdferr, mem_space_id=msid,&
        & file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i64_4d


  !============================================================================
  ! h5fort_read_str_0d — parallel では未実装
  !============================================================================
  subroutine h5fort_read_str_0d(file_id, dset_path, str, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    character(len=*), intent(out) :: str
    integer, intent(out) :: hdferr

    str = ""
    write(error_unit, '(a,a)') "[h5fort/parallel/read] ERROR: parallel string read is not implemented: ", trim(dset_path)
    hdferr = -1
  end subroutine h5fort_read_str_0d

  !============================================================================
  ! h5fort_read_lgc_{rank}d — logical (int32 から変換)
  !============================================================================
  subroutine h5fort_read_lgc_0d(file_id, dset_path, scalar, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, intent(out) :: scalar
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32) :: ival

    call h5fort_read_i32_0d(file_id, dset_path, ival, hdferr, comm, transfer_mode)
    if (hdferr == 0) scalar = (ival /= 0_int32)
  end subroutine h5fort_read_lgc_0d

  subroutine h5fort_read_lgc_1d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:)

    call h5fort_read_i32_1d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      allocate(array(size(iarray,1)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_1d

  subroutine h5fort_read_lgc_2d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:, :)

    call h5fort_read_i32_2d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      allocate(array(size(iarray,1), size(iarray,2)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_2d

  subroutine h5fort_read_lgc_3d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:, :, :)

    call h5fort_read_i32_3d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      allocate(array(size(iarray,1), size(iarray,2), size(iarray,3)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_3d

  subroutine h5fort_read_lgc_4d(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer, intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: iarray(:, :, :, :)

    call h5fort_read_i32_4d(file_id, dset_path, iarray, hdferr, comm, transfer_mode)
    if (hdferr == 0) then
      allocate(array(size(iarray,1), size(iarray,2), size(iarray,3), size(iarray,4)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_4d


  include "h5fort_parallel_read_slabs.inc"
end module h5fort_parallel_read
