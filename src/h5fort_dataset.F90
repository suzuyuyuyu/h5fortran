module h5fort_dataset
  use hdf5
  use, intrinsic :: iso_fortran_env, only: int64
  implicit none
  private

  public :: h5fort_get_dataset_info

contains

  subroutine h5fort_get_dataset_info(file_id, dset_path, rank, shape, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer, intent(out) :: rank
    integer(int64), allocatable, intent(out) :: shape(:)
    integer, intent(out) :: hdferr

    integer(hid_t) :: dset_id, space_id
    integer(hsize_t), allocatable :: dims(:), maxdims(:)
    integer :: close_error

    rank = -1
    dset_id = -1_hid_t
    space_id = -1_hid_t
    hdferr = 0

    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr == 0) call h5dget_space_f(dset_id, space_id, hdferr)
    if (hdferr == 0) call h5sget_simple_extent_ndims_f(space_id, rank, hdferr)
    if (hdferr == 0) then
      allocate(shape(rank), dims(rank), maxdims(rank))
      if (rank > 0) then
        call h5sget_simple_extent_dims_f(space_id, dims, maxdims, hdferr)
        if (hdferr >= 0) then
          shape = int(dims, int64)
          hdferr = 0
        end if
      end if
    end if

    if (space_id >= 0_hid_t) then
      call h5sclose_f(space_id, close_error)
      if (hdferr == 0) hdferr = close_error
    end if
    if (dset_id >= 0_hid_t) then
      call h5dclose_f(dset_id, close_error)
      if (hdferr == 0) hdferr = close_error
    end if
  end subroutine h5fort_get_dataset_info

end module h5fort_dataset
