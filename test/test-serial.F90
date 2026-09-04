program test_serial
  use hdf5
  use h5fort
  use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
  implicit none

  type(t_h5fort_serial) :: file, invalid
  type(t_hdf5_attr) :: attrs(1)
  integer :: i, object_index, hdferr
  integer(hid_t) :: object_id
  integer(int64) :: attribute_count
  logical :: exists
  character(len=9), parameter :: attribute_objects(3) = &
    [character(len=9) :: "/rank/two", "/rank", "/"]
  real(real64) :: r64_scalar, r64_1d(3), r64_2d(2, 3), r64_3d(2, 2, 2), r64_4d(2, 2, 2, 2)
  real(real32) :: r32_1d(2)
  integer(int32) :: i32_2d(2, 2)
  integer(int64) :: i64_1d(3)
  real(real64) :: attr_r64_scalar, attr_r64_array(3), got_attr_r64_scalar, got_attr_r64_array(3)
  real(real32) :: attr_r32_scalar, attr_r32_array(2), got_attr_r32_scalar, got_attr_r32_array(2)
  integer(int32) :: attr_i32_scalar, attr_i32_array(3), got_attr_i32_scalar, got_attr_i32_array(3)
  integer(int64) :: attr_i64_scalar, attr_i64_array(2), got_attr_i64_scalar, got_attr_i64_array(2)
  logical :: logical_2d(2, 2), logical_fixed(2, 2)
  real(real64), allocatable :: got_1d(:), got_2d(:, :), got_3d(:, :, :), got_4d(:, :, :, :)
  real(real32), allocatable :: got_r32(:)
  integer(int32), allocatable :: got_i32(:, :)
  integer(int64), allocatable :: got_i64(:), dataset_shape(:)
  integer :: dataset_rank
  logical, allocatable :: got_logical(:, :)
  character(len=:), allocatable :: got_text
  character(len=:), allocatable :: got_attr

  call assert(len_trim(H5FORTRAN_VERSION) > 0, "product version is available")
  call assert(H5FORTRAN_SCHEME_VERSION == 1, "visualization writer uses scheme 1")

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
  i64_1d = [1_int64, 2147483648_int64, huge(1_int64)]
  attr_r64_scalar = 1.25_real64
  attr_r64_array = [-2.0_real64, 0.5_real64, 4.0_real64]
  attr_r32_scalar = 2.5_real32
  attr_r32_array = [-1.0_real32, 3.0_real32]
  attr_i32_scalar = -17_int32
  attr_i32_array = [1_int32, 2_int32, 4_int32]
  attr_i64_scalar = 2147483648_int64
  attr_i64_array = [-1_int64, huge(1_int64)]
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
  call file%write("/types/i64", i64_1d); call check(file%hdferr, "int64")
  call file%write("/types/logical", logical_2d); call check(file%hdferr, "logical")
  call file%write("/types/text", "hello h5fortran"); call check(file%hdferr, "text")
  call file%write("/overwrite", 1_int32); call check(file%hdferr, "initial write")
  call file%write("/overwrite", 2_int32, mode=H5FORTRAN_FORCE_WRITE); call check(file%hdferr, "force overwrite")
  call file%write_attribute("/rank/two", "description", "updated serial test")
  call check(file%hdferr, "update dataset attribute")
  call file%write_attribute("/rank", "description", "rank group")
  call check(file%hdferr, "write group attribute")
  do object_index = 1, size(attribute_objects)
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r64_scalar", attr_r64_scalar, hdferr); call check(hdferr, "write r64 scalar attribute")
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r64_array", attr_r64_array, hdferr); call check(hdferr, "write r64 array attribute")
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r32_scalar", attr_r32_scalar, hdferr); call check(hdferr, "write r32 scalar attribute")
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r32_array", attr_r32_array, hdferr); call check(hdferr, "write r32 array attribute")
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i32_scalar", attr_i32_scalar, hdferr); call check(hdferr, "write i32 scalar attribute")
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i32_array", attr_i32_array, hdferr); call check(hdferr, "write i32 array attribute")
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i64_scalar", attr_i64_scalar, hdferr); call check(hdferr, "write i64 scalar attribute")
    call h5fort_write_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i64_array", attr_i64_array, hdferr); call check(hdferr, "write i64 array attribute")
  end do
  call file%close(); call check(file%hdferr, "close after write")

  call file%open(H5FORTRAN_READ_ONLY); call check(file%hdferr, "read-only open")
  call file%read("/rank/one", got_1d); call check(file%hdferr, "read rank 1")
  call file%read("/rank/two", got_2d); call check(file%hdferr, "read rank 2")
  call file%read("/rank/three", got_3d); call check(file%hdferr, "read rank 3")
  call file%read("/rank/four", got_4d); call check(file%hdferr, "read rank 4")
  call file%read("/types/r32", got_r32); call check(file%hdferr, "read real32")
  call file%read("/types/i32", got_i32); call check(file%hdferr, "read int32")
  call file%read("/types/i64", got_i64); call check(file%hdferr, "read int64")
  call h5fort_get_dataset_info(file%file_id, "/rank/two", dataset_rank, dataset_shape, hdferr)
  call check(hdferr, "dataset info")
  call assert(dataset_rank == 2 .and. all(dataset_shape == [2_int64, 3_int64]), "dataset rank and shape")
  call file%read("/types/logical", got_logical); call check(file%hdferr, "read logical")
  call file%read_fixed("/types/logical", logical_fixed); call check(file%hdferr, "fixed logical")
  call file%read("/types/text", got_text); call check(file%hdferr, "read text")
  call file%read_attribute("/rank/two", "description", got_attr)
  call check(file%hdferr, "read dataset attribute")
  call assert(got_attr == "updated serial test", "dataset attribute value")
  call h5fort_read_attribute(file%file_id, "/rank", "description", got_attr, hdferr)
  call check(hdferr, "procedural read group attribute")
  call assert(got_attr == "rank group", "group attribute value")
  do object_index = 1, size(attribute_objects)
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r64_scalar", got_attr_r64_scalar, hdferr); call check(hdferr, "read r64 scalar attribute")
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r64_array", got_attr_r64_array, hdferr); call check(hdferr, "read r64 array attribute")
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r32_scalar", got_attr_r32_scalar, hdferr); call check(hdferr, "read r32 scalar attribute")
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "r32_array", got_attr_r32_array, hdferr); call check(hdferr, "read r32 array attribute")
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i32_scalar", got_attr_i32_scalar, hdferr); call check(hdferr, "read i32 scalar attribute")
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i32_array", got_attr_i32_array, hdferr); call check(hdferr, "read i32 array attribute")
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i64_scalar", got_attr_i64_scalar, hdferr); call check(hdferr, "read i64 scalar attribute")
    call h5fort_read_attribute(file%file_id, trim(attribute_objects(object_index)), &
      "i64_array", got_attr_i64_array, hdferr); call check(hdferr, "read i64 array attribute")
    call assert(got_attr_r64_scalar == attr_r64_scalar .and. &
      all(got_attr_r64_array == attr_r64_array), "r64 attribute values")
    call assert(got_attr_r32_scalar == attr_r32_scalar .and. &
      all(got_attr_r32_array == attr_r32_array), "r32 attribute values")
    call assert(got_attr_i32_scalar == attr_i32_scalar .and. &
      all(got_attr_i32_array == attr_i32_array), "i32 attribute values")
    call assert(got_attr_i64_scalar == attr_i64_scalar .and. &
      all(got_attr_i64_array == attr_i64_array), "i64 attribute values")
    call h5fort_get_attribute_info(file%file_id, trim(attribute_objects(object_index)), &
      "r64_scalar", attribute_count, hdferr); call check(hdferr, "scalar attribute info")
    call assert(attribute_count == 1_int64, "scalar attribute count")
    call h5fort_get_attribute_info(file%file_id, trim(attribute_objects(object_index)), &
      "r64_array", attribute_count, hdferr); call check(hdferr, "array attribute info")
    call assert(attribute_count == size(attr_r64_array, kind=int64), "array attribute count")
  end do

  call assert(all(got_1d == r64_1d), "rank 1 value")
  call assert(all(got_2d == r64_2d), "rank 2 value")
  call assert(all(got_3d == r64_3d), "rank 3 value")
  call assert(all(got_4d == r64_4d), "rank 4 value")
  call assert(all(got_r32 == r32_1d), "real32 value")
  call assert(all(got_i32 == i32_2d), "int32 value")
  call assert(all(got_i64 == i64_1d), "int64 value")
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
  block
    real(real64) :: wrong_attribute_length(2)
    call h5fort_read_attribute(file%file_id, "/", "r64_array", wrong_attribute_length, hdferr)
    call assert(hdferr /= 0, "attribute length mismatch must fail")
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
