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
  public :: h5fort_read_str_0d
  public :: h5fort_read_lgc_0d, h5fort_read_lgc_1d, h5fort_read_lgc_2d, h5fort_read_lgc_3d, h5fort_read_lgc_4d

  character(len=*), parameter :: COUNT_DATASET_NAME = H5FORT_DSET_COUNT_DNAME
  character(len=*), parameter :: OFFSET_DATASET_NAME = H5FORT_DSET_OFFSET_DNAME

contains

  subroutine begin_parallel_read(file_id, dset_path, data_id, file_space_id, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(hid_t), intent(out) :: data_id, file_space_id, xfer_id
    integer(int64), allocatable, intent(out) :: count_(:), offset_(:)
    integer(int64), intent(out) :: nlocal, local_offset
    integer, intent(out) :: hdferr

    integer :: me, nprocs, mpi_err

    data_id = -1_hid_t
    file_space_id = -1_hid_t
    xfer_id = -1_hid_t
    hdferr = 0

    call MPI_Comm_rank(MPI_COMM_WORLD, me, mpi_err)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, mpi_err)
    if (mpi_err /= MPI_SUCCESS) then
      hdferr = -1
      return
    end if

    allocate(count_(0:nprocs - 1), offset_(0:nprocs - 1))
    call read_i64_vector(file_id, trim(dset_path)//"/"//trim(COUNT_DATASET_NAME), count_, hdferr)
    if (hdferr /= 0) return
    call read_i64_vector(file_id, trim(dset_path)//"/"//trim(OFFSET_DATASET_NAME), offset_, hdferr)
    if (hdferr /= 0) return

    nlocal = count_(me)
    local_offset = offset_(me)

    call h5dopen_f(file_id, trim(dset_path)//"/data", data_id, hdferr)
    if (hdferr /= 0) return
    call h5dget_space_f(data_id, file_space_id, hdferr)
    if (hdferr /= 0) return
    call h5pcreate_f(H5P_DATASET_XFER_F, xfer_id, hdferr)
    if (hdferr /= 0) return
    call h5pset_dxpl_mpio_f(xfer_id, H5FD_MPIO_COLLECTIVE_F, hdferr)
  end subroutine begin_parallel_read

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
    integer(hid_t) :: dset_id, h5t_i64
    integer(hsize_t) :: dims(1)
    integer :: err_local

    dims(1) = int(size(array), hsize_t)
    h5t_i64 = h5kind_to_type(int64, H5_INTEGER_KIND)
    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) return
    call h5dread_f(dset_id, h5t_i64, array, dims, hdferr)
    call h5dclose_f(dset_id, err_local)
    if (hdferr == 0) hdferr = err_local
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

  subroutine h5fort_read_r64_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), intent(out) :: scalar
    integer, intent(out) :: hdferr
    real(real64), allocatable :: array(:)

    call h5fort_read_r64_1d(file_id, dset_path, array, hdferr)
    if (hdferr == 0) then
      if (size(array) /= 1) then
        hdferr = -1
      else
        scalar = array(1)
      end if
    end if
  end subroutine h5fort_read_r64_0d

  subroutine h5fort_read_r32_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), intent(out) :: scalar
    integer, intent(out) :: hdferr
    real(real32), allocatable :: array(:)

    call h5fort_read_r32_1d(file_id, dset_path, array, hdferr)
    if (hdferr == 0) then
      if (size(array) /= 1) then
        hdferr = -1
      else
        scalar = array(1)
      end if
    end if
  end subroutine h5fort_read_r32_0d

  subroutine h5fort_read_i32_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), intent(out) :: scalar
    integer, intent(out) :: hdferr
    integer(int32), allocatable :: array(:)

    call h5fort_read_i32_1d(file_id, dset_path, array, hdferr)
    if (hdferr == 0) then
      if (size(array) /= 1) then
        hdferr = -1
      else
        scalar = array(1)
      end if
    end if
  end subroutine h5fort_read_i32_0d

  subroutine h5fort_read_str_0d(file_id, dset_path, str, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    character(len=*), intent(out) :: str
    integer, intent(out) :: hdferr

    str = ""
    write(error_unit, '(a,a)') "[h5fort_parallel_read] ERROR: parallel string read is not implemented: ", trim(dset_path)
    hdferr = -1
  end subroutine h5fort_read_str_0d

  subroutine h5fort_read_lgc_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, intent(out) :: scalar
    integer, intent(out) :: hdferr
    integer(int32) :: ival

    call h5fort_read_i32_0d(file_id, dset_path, ival, hdferr)
    if (hdferr == 0) scalar = (ival /= 0_int32)
  end subroutine h5fort_read_lgc_0d

  subroutine h5fort_read_lgc_1d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer(int32), allocatable :: iarray(:)

    call h5fort_read_i32_1d(file_id, dset_path, iarray, hdferr)
    if (hdferr == 0) then
      allocate(array(size(iarray, 1)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_1d

  subroutine h5fort_read_lgc_2d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer(int32), allocatable :: iarray(:, :)

    call h5fort_read_i32_2d(file_id, dset_path, iarray, hdferr)
    if (hdferr == 0) then
      allocate(array(size(iarray, 1), size(iarray, 2)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_2d

  subroutine h5fort_read_lgc_3d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer(int32), allocatable :: iarray(:, :, :)

    call h5fort_read_i32_3d(file_id, dset_path, iarray, hdferr)
    if (hdferr == 0) then
      allocate(array(size(iarray, 1), size(iarray, 2), size(iarray, 3)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_3d

  subroutine h5fort_read_lgc_4d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    logical, allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer(int32), allocatable :: iarray(:, :, :, :)

    call h5fort_read_i32_4d(file_id, dset_path, iarray, hdferr)
    if (hdferr == 0) then
      allocate(array(size(iarray, 1), size(iarray, 2), size(iarray, 3), size(iarray, 4)))
      array = (iarray /= 0_int32)
    end if
  end subroutine h5fort_read_lgc_4d

  subroutine h5fort_read_r64_1d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer(hsize_t) :: dims_m(1)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    allocate(array(nlocal))
    call select_1d_slab(fsid, nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_1d

  subroutine h5fort_read_r32_1d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer(hsize_t) :: dims_m(1)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    allocate(array(nlocal))
    call select_1d_slab(fsid, nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_1d

  subroutine h5fort_read_i32_1d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id, h5t_i32
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer(hsize_t) :: dims_m(1)

    h5t_i32 = h5kind_to_type(int32, H5_INTEGER_KIND)
    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    allocate(array(nlocal))
    call select_1d_slab(fsid, nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5t_i32, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_1d

  subroutine h5fort_read_r64_2d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(2)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 2) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), nlocal))
    if (hdferr == 0) call select_2d_slab(fsid, int(dims(1), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_2d

  subroutine h5fort_read_r32_2d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(2)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 2) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), nlocal))
    if (hdferr == 0) call select_2d_slab(fsid, int(dims(1), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_2d

  subroutine h5fort_read_i32_2d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id, h5t_i32
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(2)

    h5t_i32 = h5kind_to_type(int32, H5_INTEGER_KIND)
    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 2) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), nlocal))
    if (hdferr == 0) call select_2d_slab(fsid, int(dims(1), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5t_i32, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_2d

  subroutine h5fort_read_r64_3d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(3)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 3) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), nlocal))
    if (hdferr == 0) call select_3d_slab(fsid, int(dims(1), int64), int(dims(2), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_3d

  subroutine h5fort_read_r32_3d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(3)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 3) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), nlocal))
    if (hdferr == 0) call select_3d_slab(fsid, int(dims(1), int64), int(dims(2), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_3d

  subroutine h5fort_read_i32_3d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id, h5t_i32
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(3)

    h5t_i32 = h5kind_to_type(int32, H5_INTEGER_KIND)
    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 3) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), nlocal))
    if (hdferr == 0) call select_3d_slab(fsid, int(dims(1), int64), int(dims(2), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5t_i32, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_3d

  subroutine h5fort_read_r64_4d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real64), allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(4)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 4) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), dims(3), nlocal))
    if (hdferr == 0) call select_4d_slab(fsid, int(dims(1), int64), int(dims(2), int64), int(dims(3), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_DOUBLE, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r64_4d

  subroutine h5fort_read_r32_4d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    real(real32), allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(4)

    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 4) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), dims(3), nlocal))
    if (hdferr == 0) call select_4d_slab(fsid, int(dims(1), int64), int(dims(2), int64), int(dims(3), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, H5T_NATIVE_REAL, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_r32_4d

  subroutine h5fort_read_i32_4d(file_id, dset_path, array, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(int32), allocatable, intent(out) :: array(:, :, :, :)
    integer, intent(out) :: hdferr
    integer(hid_t) :: data_id, fsid, msid, xfer_id, h5t_i32
    integer(int64), allocatable :: count_(:), offset_(:)
    integer(int64) :: nlocal, local_offset
    integer :: rank
    integer(hsize_t) :: dims(MAX_RANK), dims_m(4)

    h5t_i32 = h5kind_to_type(int32, H5_INTEGER_KIND)
    call begin_parallel_read(file_id, dset_path, data_id, fsid, xfer_id, count_, offset_, nlocal, local_offset, hdferr)
    if (hdferr /= 0) return
    call get_data_rank_dims(data_id, rank, dims, hdferr)
    if (hdferr == 0 .and. rank /= 4) hdferr = -1
    if (hdferr == 0) allocate(array(dims(1), dims(2), dims(3), nlocal))
    if (hdferr == 0) call select_4d_slab(fsid, int(dims(1), int64), int(dims(2), int64), int(dims(3), int64), nlocal, local_offset, dims_m, msid, hdferr)
    if (hdferr == 0) call h5dread_f(data_id, h5t_i32, array, dims_m, hdferr, mem_space_id=msid, file_space_id=fsid, xfer_prp=xfer_id)
    call end_parallel_read(data_id, fsid, msid, xfer_id, hdferr)
  end subroutine h5fort_read_i32_4d

  include "h5fort_parallel_read_slabs.inc"

end module h5fort_parallel_read
