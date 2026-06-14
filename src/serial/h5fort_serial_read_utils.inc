  subroutine get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    integer(hid_t), intent(in) :: file_id
    character(len=*), intent(in) :: dset_path
    integer(hid_t), intent(out) :: dset_id
    integer, intent(out) :: rank
    integer(hsize_t), intent(out) :: dims(MAX_RANK)
    integer, intent(out) :: hdferr

    integer(hid_t) :: space_id
    integer(hsize_t) :: maxdims(MAX_RANK)
    integer :: err_local

    dims = 1_hsize_t
    rank = 0
    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) return

    call h5dget_space_f(dset_id, space_id, hdferr)
    if (hdferr /= 0) then
      call h5dclose_f(dset_id, err_local)
      return
    end if

    call h5sget_simple_extent_ndims_f(space_id, rank, hdferr)
    if (hdferr == 0) then
      if (rank > MAX_RANK) then
        hdferr = -1
      else
        call h5sget_simple_extent_dims_f(space_id, dims(1:rank), maxdims(1:rank), hdferr)
        if (hdferr >= 0) hdferr = 0
      end if
    end if

    call h5sclose_f(space_id, err_local)
    if (hdferr == 0) hdferr = err_local
  end subroutine get_dataset_info
