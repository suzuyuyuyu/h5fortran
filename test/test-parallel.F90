program test_parallel
  use hdf5
  use mpi
  use h5fort
  use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
  implicit none

  integer, parameter :: nrank = 4
  integer :: ierr, hdferr, me, nprocs
  integer :: value_count(0:nrank - 1), coord_count(0:nrank - 1)
  integer :: nv, nc, ov, oc
  integer(hid_t) :: file_id, fapl_id
  real(real64), allocatable :: value_all(:), value(:), value_read(:), value_fixed(:)
  real(real64), allocatable :: coord_all(:, :), coord(:, :), coord_read(:, :), coord_fixed(:, :)
  real(real32), allocatable :: zero_local(:), zero_read(:)
  integer(int32), allocatable :: int_local(:), int_read(:)
  integer(int64) :: expected_partition(0:nrank)
  logical, allocatable :: logical_local(:), logical_read(:), logical_fixed(:)
  logical :: exists
  real(real64), allocatable :: bad_dims(:, :), wrong_rank(:)

  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, me, ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
  call assert(nprocs == nrank)

  call read_input(value_count, value_all, coord_count, coord_all)

  nv = value_count(me); ov = prefix(value_count, me)
  nc = coord_count(me); oc = prefix(coord_count, me)
  allocate(value(nv), value_fixed(nv), coord(3, nc), coord_fixed(3, nc))
  value = value_all(ov + 1:ov + nv)
  coord = coord_all(:, oc + 1:oc + nc)
  allocate(zero_local(me), int_local(me + 1), logical_local(me + 1), logical_fixed(me + 1))
  zero_local = real(me, real32)
  int_local = int(me, int32)
  logical_local = mod(me, 2) == 0

  call h5open_f(hdferr); call check(hdferr)

  call open_file("test-parallel.h5", H5F_ACC_TRUNC_F, file_id, hdferr); call check(hdferr)
  call h5fort_pwrite(file_id, "/value", value, hdferr); call check(hdferr)
  call h5fort_pwrite(file_id, "/coord", coord, hdferr); call check(hdferr)
  call h5fort_pwrite(file_id, "/zero", zero_local, hdferr); call check(hdferr)
  call h5fort_pwrite(file_id, "/integer", int_local, hdferr); call check(hdferr)
  call h5fort_pwrite(file_id, "/logical", logical_local, hdferr); call check(hdferr)
  allocate(bad_dims(me + 1, 1))
  call h5fort_pwrite(file_id, "/bad-dimensions", bad_dims, hdferr)
  call assert(hdferr /= 0)
  deallocate(bad_dims)
  call h5fclose_f(file_id, hdferr); call check(hdferr)

  call open_file("test-parallel.h5", H5F_ACC_RDONLY_F, file_id, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/value", value_read, hdferr); call check(hdferr)
  call h5fort_pread_fixed(file_id, "/value", value_fixed, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/coord", coord_read, hdferr); call check(hdferr)
  call h5fort_pread_fixed(file_id, "/coord", coord_fixed, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/zero", zero_read, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/integer", int_read, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/logical", logical_read, hdferr); call check(hdferr)
  call h5fort_pread_fixed(file_id, "/logical", logical_fixed, hdferr); call check(hdferr)
  call assert(all(abs(value_read - value) < 1.0e-12_real64))
  call assert(all(abs(value_fixed - value) < 1.0e-12_real64))
  call assert(all(abs(coord_read - coord) < 1.0e-12_real64))
  call assert(all(abs(coord_fixed - coord) < 1.0e-12_real64))
  call assert(all(zero_read == zero_local))
  call assert(all(int_read == int_local))
  call assert(all(logical_read .eqv. logical_local))
  call assert(all(logical_fixed .eqv. logical_local))
  call h5fort_pread(file_id, "/coord", wrong_rank, hdferr)
  call assert(hdferr /= 0)
  call h5fort_pread(file_id, "/missing", wrong_rank, hdferr)
  call assert(hdferr /= 0)
  call h5lexists_f(file_id, "/value/__partition__", exists, hdferr); call check(hdferr)
  call assert(exists)
  call h5lexists_f(file_id, "/value/__count__", exists, hdferr); call check(hdferr)
  call assert(.not. exists)
  call h5lexists_f(file_id, "/value/__offset__", exists, hdferr); call check(hdferr)
  call assert(.not. exists)
  call h5fclose_f(file_id, hdferr); call check(hdferr)

  expected_partition(0) = 0_int64
  do nc = 0, nrank - 1
    expected_partition(nc + 1) = expected_partition(nc) + int(value_count(nc), int64)
  end do
  expected_partition(nrank) = expected_partition(nrank) + 1_int64
  call open_file("test-parallel.h5", H5F_ACC_RDWR_F, file_id, hdferr); call check(hdferr)
  call overwrite_partition(file_id, "/value/__partition__", expected_partition, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/value", wrong_rank, hdferr)
  call assert(hdferr /= 0)
  call h5fclose_f(file_id, hdferr); call check(hdferr)

  block
    type(t_h5fort_parallel) :: h5fp
    call h5fp%open()
    call assert(h5fp%hdferr /= 0)
    h5fp%f_name = "file-that-does-not-exist.h5"
    call h5fp%open(H5FORTRAN_READ_ONLY)
    call assert(h5fp%hdferr /= 0)
    h5fp%f_name = "test-parallel-class.h5"
    call h5fp%open(mode=H5FORTRAN_FORCE_WRITE); call check(h5fp%hdferr)
    call h5fp%write("/value", value);           call check(h5fp%hdferr)
    call h5fp%write("/coord", coord);           call check(h5fp%hdferr)
    call h5fp%close();                          call check(h5fp%hdferr)

    call h5fp%open(H5FORTRAN_READ_ONLY); call check(h5fp%hdferr)
    call h5fp%read("/value", value_read);           call check(h5fp%hdferr)
    call h5fp%read_fixed("/value", value_fixed);    call check(h5fp%hdferr)
    call h5fp%read("/coord", coord_read);           call check(h5fp%hdferr)
    call h5fp%read_fixed("/coord", coord_fixed);    call check(h5fp%hdferr)
    call assert(all(abs(value_read  - value) < 1.0e-12_real64))
    call assert(all(abs(value_fixed - value) < 1.0e-12_real64))
    call assert(all(abs(coord_read  - coord) < 1.0e-12_real64))
    call assert(all(abs(coord_fixed - coord) < 1.0e-12_real64))
    call h5fp%close(); call check(h5fp%hdferr)
    call h5fp%close(); call assert(h5fp%hdferr /= 0)
  end block

  call h5close_f(hdferr); call check(hdferr)

  call MPI_Finalize(ierr)

contains

  subroutine read_input(count1, value, count2, coord)
    integer, intent(out) :: count1(0:), count2(0:)
    real(real64), allocatable, intent(out) :: value(:), coord(:, :)
    integer :: u, i
    character(len=8) :: tag

    open(newunit=u, file="input-parallel.dat", status="old", action="read")
    read(u, *) tag
    read(u, *) count1
    allocate(value(sum(count1)))
    read(u, *) value
    read(u, *) tag
    read(u, *) count2
    allocate(coord(3, sum(count2)))
    do i = 1, size(coord, 2)
      read(u, *) coord(:, i)
    end do
    close(u)
  end subroutine read_input

  subroutine open_file(path, mode, fid, ierr_out)
    character(len=*), intent(in) :: path
    integer, intent(in) :: mode
    integer(hid_t), intent(out) :: fid
    integer, intent(out) :: ierr_out

    call h5pcreate_f(H5P_FILE_ACCESS_F, fapl_id, ierr_out)
    if (ierr_out == 0) call h5pset_fapl_mpio_f(fapl_id, MPI_COMM_WORLD, MPI_INFO_NULL, ierr_out)
    if (ierr_out == 0 .and. mode == H5F_ACC_TRUNC_F) call h5fcreate_f(path, mode, fid, ierr_out, access_prp=fapl_id)
    if (ierr_out == 0 .and. mode /= H5F_ACC_TRUNC_F) call h5fopen_f(path, mode, fid, ierr_out, access_prp=fapl_id)
    call h5pclose_f(fapl_id, hdferr)
    if (ierr_out == 0) ierr_out = hdferr
  end subroutine open_file

  subroutine overwrite_partition(fid, path, partition, ierr_out)
    integer(hid_t), intent(in) :: fid
    character(len=*), intent(in) :: path
    integer(int64), intent(in) :: partition(0:)
    integer, intent(out) :: ierr_out
    integer(hid_t) :: dset_id, xfer_id, h5t_i64
    integer(hsize_t) :: dims(1)
    integer :: close_err

    dset_id = -1_hid_t
    xfer_id = -1_hid_t
    dims(1) = int(size(partition), hsize_t)
    h5t_i64 = h5kind_to_type(int64, H5_INTEGER_KIND)
    call h5dopen_f(fid, path, dset_id, ierr_out)
    if (ierr_out == 0) call h5pcreate_f(H5P_DATASET_XFER_F, xfer_id, ierr_out)
    if (ierr_out == 0) call h5pset_dxpl_mpio_f(xfer_id, H5FD_MPIO_COLLECTIVE_F, ierr_out)
    if (ierr_out == 0) call h5dwrite_f(dset_id, h5t_i64, partition, dims, ierr_out, xfer_prp=xfer_id)
    if (xfer_id >= 0_hid_t) then
      call h5pclose_f(xfer_id, close_err)
      if (ierr_out == 0) ierr_out = close_err
    end if
    if (dset_id >= 0_hid_t) then
      call h5dclose_f(dset_id, close_err)
      if (ierr_out == 0) ierr_out = close_err
    end if
  end subroutine overwrite_partition

  integer function prefix(count, rank)
    integer, intent(in) :: count(0:)
    integer, intent(in) :: rank
    integer :: r
    prefix = 0
    do r = 0, rank - 1
      prefix = prefix + count(r)
    end do
  end function prefix

  subroutine check(ierr_in)
    integer, intent(in) :: ierr_in
    if (ierr_in /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  end subroutine check

  subroutine assert(ok)
    logical, intent(in) :: ok
    if (.not. ok) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  end subroutine assert

end program test_parallel
