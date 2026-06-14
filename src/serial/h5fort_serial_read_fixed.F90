! 固定長（非allocatable）配列向け。Fortranのジェネリック解決はallocatable属性を
! 区別しないため、hdf5_read とは別インターフェースとして提供する。
#include "check_shape_and_copy.inc"
module h5fort_serial_read_fixed
  use hdf5
  use, intrinsic :: iso_fortran_env
  use h5fort_serial_read
  implicit none
  private

  public :: h5fort_read_r64_1d_fixed, h5fort_read_r64_2d_fixed, h5fort_read_r64_3d_fixed, h5fort_read_r64_4d_fixed
  public :: h5fort_read_r32_1d_fixed, h5fort_read_r32_2d_fixed, h5fort_read_r32_3d_fixed, h5fort_read_r32_4d_fixed
  public :: h5fort_read_i32_1d_fixed, h5fort_read_i32_2d_fixed, h5fort_read_i32_3d_fixed, h5fort_read_i32_4d_fixed

contains

  subroutine h5fort_read_r64_1d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),     intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    real(real64), allocatable :: tmp(:)
    call h5fort_read_r64_1d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r64_1d_fixed

  subroutine h5fort_read_r64_2d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),     intent(out) :: array(:,:)
    integer,          intent(out) :: hdferr
    real(real64), allocatable :: tmp(:,:)
    call h5fort_read_r64_2d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r64_2d_fixed

  subroutine h5fort_read_r64_3d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),     intent(out) :: array(:,:,:)
    integer,          intent(out) :: hdferr
    real(real64), allocatable :: tmp(:,:,:)
    call h5fort_read_r64_3d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r64_3d_fixed

  subroutine h5fort_read_r64_4d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),     intent(out) :: array(:,:,:,:)
    integer,          intent(out) :: hdferr
    real(real64), allocatable :: tmp(:,:,:,:)
    call h5fort_read_r64_4d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r64_4d_fixed

  subroutine h5fort_read_r32_1d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),     intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    real(real32), allocatable :: tmp(:)
    call h5fort_read_r32_1d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r32_1d_fixed

  subroutine h5fort_read_r32_2d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),     intent(out) :: array(:,:)
    integer,          intent(out) :: hdferr
    real(real32), allocatable :: tmp(:,:)
    call h5fort_read_r32_2d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r32_2d_fixed

  subroutine h5fort_read_r32_3d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),     intent(out) :: array(:,:,:)
    integer,          intent(out) :: hdferr
    real(real32), allocatable :: tmp(:,:,:)
    call h5fort_read_r32_3d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r32_3d_fixed

  subroutine h5fort_read_r32_4d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),     intent(out) :: array(:,:,:,:)
    integer,          intent(out) :: hdferr
    real(real32), allocatable :: tmp(:,:,:,:)
    call h5fort_read_r32_4d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_r32_4d_fixed

  subroutine h5fort_read_i32_1d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),   intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    integer(int32), allocatable :: tmp(:)
    call h5fort_read_i32_1d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_i32_1d_fixed

  subroutine h5fort_read_i32_2d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),   intent(out) :: array(:,:)
    integer,          intent(out) :: hdferr
    integer(int32), allocatable :: tmp(:,:)
    call h5fort_read_i32_2d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_i32_2d_fixed

  subroutine h5fort_read_i32_3d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),   intent(out) :: array(:,:,:)
    integer,          intent(out) :: hdferr
    integer(int32), allocatable :: tmp(:,:,:)
    call h5fort_read_i32_3d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_i32_3d_fixed

  subroutine h5fort_read_i32_4d_fixed(file_id, dset_path, array, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),   intent(out) :: array(:,:,:,:)
    integer,          intent(out) :: hdferr
    integer(int32), allocatable :: tmp(:,:,:,:)
    call h5fort_read_i32_4d(file_id, dset_path, tmp, hdferr)
    if (hdferr /= 0) return
    CHECK_SHAPE_AND_COPY(serial, tmp, array)
  end subroutine h5fort_read_i32_4d_fixed

end module h5fort_serial_read_fixed
