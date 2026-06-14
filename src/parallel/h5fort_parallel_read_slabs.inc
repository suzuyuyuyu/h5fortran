  subroutine select_1d_slab(fsid, nlocal, off, dims_m, msid, hdferr)
    integer(hid_t), intent(in) :: fsid
    integer(int64), intent(in) :: nlocal, off
    integer(hsize_t), intent(out) :: dims_m(1)
    integer(hid_t), intent(out) :: msid
    integer, intent(out) :: hdferr

    integer(hsize_t) :: hstart(1), hcount(1)

    dims_m(1) = int(max(nlocal, 1_int64), hsize_t)
    if (nlocal > 0_int64) then
      hstart(1) = int(off, hsize_t)
      hcount(1) = int(nlocal, hsize_t)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      if (hdferr /= 0) return
      dims_m(1) = int(nlocal, hsize_t)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      if (hdferr /= 0) return
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if
  end subroutine select_1d_slab

  subroutine select_2d_slab(fsid, n1, nlocal, off, dims_m, msid, hdferr)
    integer(hid_t), intent(in) :: fsid
    integer(int64), intent(in) :: n1, nlocal, off
    integer(hsize_t), intent(out) :: dims_m(2)
    integer(hid_t), intent(out) :: msid
    integer, intent(out) :: hdferr

    integer(hsize_t) :: hstart(2), hcount(2)

    dims_m = [int(n1, hsize_t), int(max(nlocal, 1_int64), hsize_t)]
    if (nlocal > 0_int64) then
      hstart = [0_hsize_t, int(off, hsize_t)]
      hcount = [int(n1, hsize_t), int(nlocal, hsize_t)]
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      if (hdferr /= 0) return
      dims_m(2) = int(nlocal, hsize_t)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      if (hdferr /= 0) return
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if
  end subroutine select_2d_slab

  subroutine select_3d_slab(fsid, n1, n2, nlocal, off, dims_m, msid, hdferr)
    integer(hid_t), intent(in) :: fsid
    integer(int64), intent(in) :: n1, n2, nlocal, off
    integer(hsize_t), intent(out) :: dims_m(3)
    integer(hid_t), intent(out) :: msid
    integer, intent(out) :: hdferr

    integer(hsize_t) :: hstart(3), hcount(3)

    dims_m = [int(n1, hsize_t), int(n2, hsize_t), int(max(nlocal, 1_int64), hsize_t)]
    if (nlocal > 0_int64) then
      hstart = [0_hsize_t, 0_hsize_t, int(off, hsize_t)]
      hcount = [int(n1, hsize_t), int(n2, hsize_t), int(nlocal, hsize_t)]
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      if (hdferr /= 0) return
      dims_m(3) = int(nlocal, hsize_t)
      call h5screate_simple_f(3, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      if (hdferr /= 0) return
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if
  end subroutine select_3d_slab

  subroutine select_4d_slab(fsid, n1, n2, n3, nlocal, off, dims_m, msid, hdferr)
    integer(hid_t), intent(in) :: fsid
    integer(int64), intent(in) :: n1, n2, n3, nlocal, off
    integer(hsize_t), intent(out) :: dims_m(4)
    integer(hid_t), intent(out) :: msid
    integer, intent(out) :: hdferr

    integer(hsize_t) :: hstart(4), hcount(4)

    dims_m = [int(n1, hsize_t), int(n2, hsize_t), int(n3, hsize_t), int(max(nlocal, 1_int64), hsize_t)]
    if (nlocal > 0_int64) then
      hstart = [0_hsize_t, 0_hsize_t, 0_hsize_t, int(off, hsize_t)]
      hcount = [int(n1, hsize_t), int(n2, hsize_t), int(n3, hsize_t), int(nlocal, hsize_t)]
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      if (hdferr /= 0) return
      dims_m(4) = int(nlocal, hsize_t)
      call h5screate_simple_f(4, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      if (hdferr /= 0) return
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if
  end subroutine select_4d_slab
