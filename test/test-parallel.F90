program test_parallel
  use hdf5
  use mpi
  use h5fort
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  integer, parameter :: nrank = 4
  integer :: ierr, hdferr, me, nprocs
  integer :: value_count(0:nrank - 1), coord_count(0:nrank - 1)
  integer :: nv, nc, ov, oc
  integer(hid_t) :: file_id, fapl_id
  real(real64), allocatable :: value_all(:), value(:), value_read(:), value_fixed(:)
  real(real64), allocatable :: coord_all(:, :), coord(:, :), coord_read(:, :), coord_fixed(:, :)

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

  call h5open_f(hdferr); call check(hdferr)
  call open_file("test-parallel.h5", H5F_ACC_TRUNC_F, file_id, hdferr); call check(hdferr)
  call h5fort_pwrite(file_id, "/value", value, hdferr); call check(hdferr)
  call h5fort_pwrite(file_id, "/coord", coord, hdferr); call check(hdferr)
  call h5fclose_f(file_id, hdferr); call check(hdferr)

  call open_file("test-parallel.h5", H5F_ACC_RDONLY_F, file_id, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/value", value_read, hdferr); call check(hdferr)
  call h5fort_pread_fixed(file_id, "/value", value_fixed, hdferr); call check(hdferr)
  call h5fort_pread(file_id, "/coord", coord_read, hdferr); call check(hdferr)
  call h5fort_pread_fixed(file_id, "/coord", coord_fixed, hdferr); call check(hdferr)
  call assert(all(abs(value_read - value) < 1.0e-12_real64))
  call assert(all(abs(value_fixed - value) < 1.0e-12_real64))
  call assert(all(abs(coord_read - coord) < 1.0e-12_real64))
  call assert(all(abs(coord_fixed - coord) < 1.0e-12_real64))
  call h5fclose_f(file_id, hdferr); call check(hdferr)
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
