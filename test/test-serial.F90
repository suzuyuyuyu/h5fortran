program test_serial
  use hdf5
  use h5fort
  use, intrinsic :: iso_fortran_env, only: int32, real32, real64
  implicit none

  type(t_h5fort_serial) :: file, invalid
  type(t_hdf5_attr) :: attrs(1)
  integer :: i, hdferr
  integer(hid_t) :: object_id
  logical :: exists
  real(real64) :: r64_scalar, r64_1d(3), r64_2d(2, 3), r64_3d(2, 2, 2), r64_4d(2, 2, 2, 2)
  real(real32) :: r32_1d(2)
  integer(int32) :: i32_2d(2, 2)
  logical :: logical_2d(2, 2), logical_fixed(2, 2)
  real(real64), allocatable :: got_1d(:), got_2d(:, :), got_3d(:, :, :), got_4d(:, :, :, :)
  real(real32), allocatable :: got_r32(:)
  integer(int32), allocatable :: got_i32(:, :)
  logical, allocatable :: got_logical(:, :)
  character(len=:), allocatable :: got_text
  character(len=:), allocatable :: got_attr

  call h5open_f(hdferr); call check(hdferr, "HDF5 initialization")

  call invalid%open()
  call assert(invalid%hdferr /= 0, "open without f_name must fail")

  r64_scalar = 2.5_real64
  r64_1d = [1.0_real64, 2.0_real64, 3.0_real64]
  r64_2d = reshape([(real(i, real64), i = 1, size(r64_2d))], shape(r64_2d))
  r64_3d = reshape([(real(i, real64), i = 1, size(r64_3d))], shape(r64_3d))
  r64_4d = reshape([(real(i, real64), i = 1, size(r64_4d))], shape(r64_4d))
  r32_1d = [1.25_real32, 2.5_real32]
  i32_2d = reshape([1_int32, 2_int32, 3_int32, 4_int32], shape(i32_2d))
  logical_2d = reshape([.true., .false., .false., .true.], shape(logical_2d))
  attrs(1) = t_hdf5_attr("description", "serial test")

  file%f_name = "test-serial.h5"
  call file%open(H5FORTRAN_FORCE_WRITE); call check(file%hdferr, "create")
  call file%open(); call assert(file%hdferr /= 0, "double open must fail")
  call file%write("/scalar/r64", r64_scalar); call check(file%hdferr, "r64 scalar")
  call file%write("/rank/one", r64_1d); call check(file%hdferr, "rank 1")
  call file%write("/rank/two", r64_2d, attrs=attrs, units="m/s"); call check(file%hdferr, "rank 2")
  call file%write("/rank/three", r64_3d); call check(file%hdferr, "rank 3")
  call file%write("/rank/four", r64_4d); call check(file%hdferr, "rank 4")
  call file%write("/types/r32", r32_1d); call check(file%hdferr, "real32")
  call file%write("/types/i32", i32_2d); call check(file%hdferr, "int32")
  call file%write("/types/logical", logical_2d); call check(file%hdferr, "logical")
  call file%write("/types/text", "hello h5fortran"); call check(file%hdferr, "text")
  call file%write("/overwrite", 1_int32); call check(file%hdferr, "initial write")
  call file%write("/overwrite", 2_int32, mode=H5FORTRAN_FORCE_WRITE); call check(file%hdferr, "force overwrite")
  call file%write_attribute("/rank/two", "description", "updated serial test")
  call check(file%hdferr, "update dataset attribute")
  call file%write_attribute("/rank", "description", "rank group")
  call check(file%hdferr, "write group attribute")
  call file%close(); call check(file%hdferr, "close after write")

  call file%open(H5FORTRAN_READ_ONLY); call check(file%hdferr, "read-only open")
  call file%read("/rank/one", got_1d); call check(file%hdferr, "read rank 1")
  call file%read("/rank/two", got_2d); call check(file%hdferr, "read rank 2")
  call file%read("/rank/three", got_3d); call check(file%hdferr, "read rank 3")
  call file%read("/rank/four", got_4d); call check(file%hdferr, "read rank 4")
  call file%read("/types/r32", got_r32); call check(file%hdferr, "read real32")
  call file%read("/types/i32", got_i32); call check(file%hdferr, "read int32")
  call file%read("/types/logical", got_logical); call check(file%hdferr, "read logical")
  call file%read_fixed("/types/logical", logical_fixed); call check(file%hdferr, "fixed logical")
  call file%read("/types/text", got_text); call check(file%hdferr, "read text")
  call file%read_attribute("/rank/two", "description", got_attr)
  call check(file%hdferr, "read dataset attribute")
  call assert(got_attr == "updated serial test", "dataset attribute value")
  call h5fort_read_attribute(file%file_id, "/rank", "description", got_attr, hdferr)
  call check(hdferr, "procedural read group attribute")
  call assert(got_attr == "rank group", "group attribute value")

  call assert(all(got_1d == r64_1d), "rank 1 value")
  call assert(all(got_2d == r64_2d), "rank 2 value")
  call assert(all(got_3d == r64_3d), "rank 3 value")
  call assert(all(got_4d == r64_4d), "rank 4 value")
  call assert(all(got_r32 == r32_1d), "real32 value")
  call assert(all(got_i32 == i32_2d), "int32 value")
  call assert(all(got_logical .eqv. logical_2d), "logical value")
  call assert(all(logical_fixed .eqv. logical_2d), "fixed logical value")
  call assert(got_text == "hello h5fortran", "text value")

  call h5oopen_f(file%file_id, "/rank/two", object_id, hdferr); call check(hdferr, "open attribute object")
  call h5aexists_f(object_id, "description", exists, hdferr); call check(hdferr, "description exists")
  call assert(exists, "description attribute")
  call h5aexists_f(object_id, "units", exists, hdferr); call check(hdferr, "units exists")
  call assert(exists, "units attribute")
  call h5oclose_f(object_id, hdferr); call check(hdferr, "close attribute object")

  call file%read("/missing", got_1d)
  call assert(file%hdferr /= 0, "missing path must fail")
  call file%read("/rank/two", got_1d)
  call assert(file%hdferr /= 0, "rank mismatch must fail")
  block
    real(real64) :: wrong_shape(1, 1)
    call file%read_fixed("/rank/two", wrong_shape)
    call assert(file%hdferr /= 0, "shape mismatch must fail")
  end block
  call file%write("/read-only-write", r64_1d)
  call assert(file%hdferr /= 0, "write through read-only handle must fail")

  call file%close(); call check(file%hdferr, "close after read")
  call file%close(); call assert(file%hdferr /= 0, "double close must fail")
  call h5close_f(hdferr); call check(hdferr, "HDF5 finalization")

contains

  subroutine check(ierr, context)
    integer, intent(in) :: ierr
    character(len=*), intent(in) :: context
    if (ierr /= 0) then
      write(*, '(a,2a,i0)') "failure: ", context, ", error=", ierr
      error stop 1
    end if
  end subroutine check

  subroutine assert(ok, context)
    logical, intent(in) :: ok
    character(len=*), intent(in) :: context
    if (.not. ok) then
      write(*, '(2a)') "assertion failed: ", context
      error stop 1
    end if
  end subroutine assert

end program test_serial
