! DO NOT EDIT — generated from src/fypp/serial/h5fort_serial_attribute.fypp
! To regenerate: src/fypp/generate_fypp.sh
module h5fort_serial_attribute
  use hdf5
  use, intrinsic :: iso_fortran_env, only: error_unit
  implicit none
  private

  public :: t_hdf5_attr
  public :: h5fort_swrite_attr
  public :: h5fort_write_attribute
  public :: h5fort_read_attribute

  integer, parameter :: ATTR_NAME_LEN  = 64
  integer, parameter :: ATTR_VALUE_LEN = 256

  type :: t_hdf5_attr
    character(len=ATTR_NAME_LEN)  :: name  = ""
    character(len=ATTR_VALUE_LEN) :: value = ""
  end type t_hdf5_attr

contains

  subroutine record_error(first_error, latest_error)
    integer, intent(inout) :: first_error
    integer, intent(in) :: latest_error
    if (first_error == 0 .and. latest_error /= 0) first_error = latest_error
  end subroutine record_error

  !============================================================================
  ! h5fort_swrite_attr: 複数の文字列 attribute をまとめて書き込む互換 API
  !============================================================================
  subroutine h5fort_swrite_attr(file_id, obj_path, attrs, hdferr)
    integer(hid_t),    intent(in)  :: file_id
    character(len=*),  intent(in)  :: obj_path
    type(t_hdf5_attr), intent(in)  :: attrs(:)
    integer,           intent(out) :: hdferr

    integer :: i, err_local

    hdferr = 0
    do i = 1, size(attrs)
      if (len_trim(attrs(i)%name) == 0) cycle
      call h5fort_write_attribute(file_id, obj_path, trim(attrs(i)%name), trim(attrs(i)%value), err_local)
      call record_error(hdferr, err_local)
    end do
  end subroutine h5fort_swrite_attr

  !============================================================================
  ! h5fort_write_attribute: データセット/グループに文字列 attribute を書く
  !============================================================================
  subroutine h5fort_write_attribute(file_id, obj_path, name, value, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: obj_path
    character(len=*), intent(in)  :: name
    character(len=*), intent(in)  :: value
    integer,          intent(out) :: hdferr

    integer(hid_t)   :: obj_id, attr_id, str_type_id, space_id
    integer(hsize_t) :: dims(1)
    integer(size_t)  :: str_len
    integer          :: err_local
    logical          :: attr_exists

    dims = [1_hsize_t]
    hdferr = 0

    if (len_trim(name) == 0) then
      hdferr = -1
      return
    end if

    call h5oopen_f(file_id, trim(obj_path), obj_id, hdferr)
    if (hdferr /= 0) then
      write(error_unit,'(A,A)') "[h5fort/serial/attribute] ERROR: h5oopen_f failed for: ", trim(obj_path)
      return
    end if

    call h5tcopy_f(H5T_FORTRAN_S1, str_type_id, err_local)
    call record_error(hdferr, err_local)
    if (err_local /= 0) then
      call h5oclose_f(obj_id, err_local)
      return
    end if

    str_len = max(1_size_t, int(len_trim(value), size_t))
    call h5tset_size_f(str_type_id, str_len, err_local)
    call record_error(hdferr, err_local)
    if (err_local /= 0) then
      call h5tclose_f(str_type_id, err_local)
      call h5oclose_f(obj_id, err_local)
      return
    end if

    call h5screate_f(H5S_SCALAR_F, space_id, err_local)
    call record_error(hdferr, err_local)
    if (err_local /= 0) then
      call h5tclose_f(str_type_id, err_local)
      call h5oclose_f(obj_id, err_local)
      return
    end if

    call h5aexists_f(obj_id, trim(name), attr_exists, err_local)
    call record_error(hdferr, err_local)
    if (err_local == 0 .and. attr_exists) then
      call h5adelete_f(obj_id, trim(name), err_local)
      call record_error(hdferr, err_local)
    end if

    if (err_local == 0) call h5acreate_f(obj_id, trim(name), str_type_id, space_id, attr_id, err_local)
    call record_error(hdferr, err_local)
    if (err_local /= 0) then
      write(error_unit,'(A,A)') "[h5fort/serial/attribute] ERROR: h5acreate_f failed for: ", trim(name)
    else
      call h5awrite_f(attr_id, str_type_id, value, dims, err_local)
      call record_error(hdferr, err_local)
      call h5aclose_f(attr_id, err_local)
      call record_error(hdferr, err_local)
    end if

    call h5sclose_f(space_id, err_local)
    call record_error(hdferr, err_local)
    call h5tclose_f(str_type_id, err_local)
    call record_error(hdferr, err_local)
    call h5oclose_f(obj_id, err_local)
    call record_error(hdferr, err_local)
  end subroutine h5fort_write_attribute

  !============================================================================
  ! h5fort_read_attribute: 文字列 attribute を可変長文字列へ読み込む
  !============================================================================
  subroutine h5fort_read_attribute(file_id, obj_path, name, value, hdferr)
    integer(hid_t),                intent(in)  :: file_id
    character(len=*),              intent(in)  :: obj_path
    character(len=*),              intent(in)  :: name
    character(len=:), allocatable, intent(out) :: value
    integer,                       intent(out) :: hdferr

    integer(hid_t)   :: obj_id, attr_id, str_type_id
    integer(hsize_t) :: dims(1)
    integer(size_t)  :: str_len
    integer          :: err_local

    dims = [1_hsize_t]
    hdferr = 0
    str_type_id = -1_hid_t

    call h5oopen_f(file_id, trim(obj_path), obj_id, hdferr)
    if (hdferr /= 0) then
      write(error_unit,'(A,A)') "[h5fort/serial/attribute] ERROR: h5oopen_f failed for: ", trim(obj_path)
      return
    end if

    call h5aopen_f(obj_id, trim(name), attr_id, hdferr)
    if (hdferr /= 0) then
      write(error_unit,'(A,A)') "[h5fort/serial/attribute] ERROR: h5aopen_f failed for: ", trim(name)
      call h5oclose_f(obj_id, err_local)
      return
    end if

    call h5aget_type_f(attr_id, str_type_id, err_local)
    call record_error(hdferr, err_local)
    if (err_local == 0) then
      call h5tget_size_f(str_type_id, str_len, err_local)
      call record_error(hdferr, err_local)
    end if

    if (hdferr == 0) then
      allocate(character(len=str_len) :: value)
      call h5aread_f(attr_id, str_type_id, value, dims, err_local)
      call record_error(hdferr, err_local)
    end if

    if (str_type_id >= 0_hid_t) then
      call h5tclose_f(str_type_id, err_local)
      call record_error(hdferr, err_local)
    end if
    call h5aclose_f(attr_id, err_local)
    call record_error(hdferr, err_local)
    call h5oclose_f(obj_id, err_local)
    call record_error(hdferr, err_local)
  end subroutine h5fort_read_attribute

end module h5fort_serial_attribute
