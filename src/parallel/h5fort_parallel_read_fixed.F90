! DO NOT EDIT — generated from src/fypp/parallel/h5fort_parallel_read_fixed.fypp
! To regenerate: src/fypp/generate_fypp.sh
! 固定長（非allocatable）配列向け。allocatable版を呼んでから形状チェック・コピーする。

module h5fort_parallel_read_fixed
  use hdf5
  use, intrinsic :: iso_fortran_env
  use h5fort_parallel_read
  implicit none
  private

  public :: h5fort_read_r64_1d_fixed
  public :: h5fort_read_r64_2d_fixed
  public :: h5fort_read_r64_3d_fixed
  public :: h5fort_read_r64_4d_fixed
  public :: h5fort_read_r32_1d_fixed
  public :: h5fort_read_r32_2d_fixed
  public :: h5fort_read_r32_3d_fixed
  public :: h5fort_read_r32_4d_fixed
  public :: h5fort_read_i32_1d_fixed
  public :: h5fort_read_i32_2d_fixed
  public :: h5fort_read_i32_3d_fixed
  public :: h5fort_read_i32_4d_fixed
  public :: h5fort_read_i64_1d_fixed
  public :: h5fort_read_i64_2d_fixed
  public :: h5fort_read_i64_3d_fixed
  public :: h5fort_read_i64_4d_fixed
  public :: h5fort_read_lgc_1d_fixed
  public :: h5fort_read_lgc_2d_fixed
  public :: h5fort_read_lgc_3d_fixed
  public :: h5fort_read_lgc_4d_fixed

contains

  subroutine h5fort_read_r64_1d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real64), allocatable :: tmp(:)
    call h5fort_read_r64_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r64_1d_fixed

  subroutine h5fort_read_r64_2d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real64), allocatable :: tmp(:, :)
    call h5fort_read_r64_2d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r64_2d_fixed

  subroutine h5fort_read_r64_3d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real64), allocatable :: tmp(:, :, :)
    call h5fort_read_r64_3d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r64_3d_fixed

  subroutine h5fort_read_r64_4d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),        intent(out) :: array(:, :, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real64), allocatable :: tmp(:, :, :, :)
    call h5fort_read_r64_4d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r64_4d_fixed

  subroutine h5fort_read_r32_1d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real32), allocatable :: tmp(:)
    call h5fort_read_r32_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r32_1d_fixed

  subroutine h5fort_read_r32_2d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real32), allocatable :: tmp(:, :)
    call h5fort_read_r32_2d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r32_2d_fixed

  subroutine h5fort_read_r32_3d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real32), allocatable :: tmp(:, :, :)
    call h5fort_read_r32_3d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r32_3d_fixed

  subroutine h5fort_read_r32_4d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),        intent(out) :: array(:, :, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    real(real32), allocatable :: tmp(:, :, :, :)
    call h5fort_read_r32_4d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_r32_4d_fixed

  subroutine h5fort_read_i32_1d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: tmp(:)
    call h5fort_read_i32_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i32_1d_fixed

  subroutine h5fort_read_i32_2d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: tmp(:, :)
    call h5fort_read_i32_2d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i32_2d_fixed

  subroutine h5fort_read_i32_3d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: tmp(:, :, :)
    call h5fort_read_i32_3d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i32_3d_fixed

  subroutine h5fort_read_i32_4d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),        intent(out) :: array(:, :, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int32), allocatable :: tmp(:, :, :, :)
    call h5fort_read_i32_4d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i32_4d_fixed

  subroutine h5fort_read_i64_1d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int64),        intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int64), allocatable :: tmp(:)
    call h5fort_read_i64_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i64_1d_fixed

  subroutine h5fort_read_i64_2d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int64),        intent(out) :: array(:, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int64), allocatable :: tmp(:, :)
    call h5fort_read_i64_2d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i64_2d_fixed

  subroutine h5fort_read_i64_3d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int64),        intent(out) :: array(:, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int64), allocatable :: tmp(:, :, :)
    call h5fort_read_i64_3d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i64_3d_fixed

  subroutine h5fort_read_i64_4d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int64),        intent(out) :: array(:, :, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    integer(int64), allocatable :: tmp(:, :, :, :)
    call h5fort_read_i64_4d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_i64_4d_fixed


  subroutine h5fort_read_lgc_1d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    logical, allocatable :: tmp(:)
    call h5fort_read_lgc_1d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_lgc_1d_fixed

  subroutine h5fort_read_lgc_2d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    logical, allocatable :: tmp(:, :)
    call h5fort_read_lgc_2d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_lgc_2d_fixed

  subroutine h5fort_read_lgc_3d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    logical, allocatable :: tmp(:, :, :)
    call h5fort_read_lgc_3d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_lgc_3d_fixed

  subroutine h5fort_read_lgc_4d_fixed(file_id, dset_path, array, hdferr, comm, transfer_mode)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: array(:, :, :, :)
    integer,          intent(out) :: hdferr
    integer,          intent(in), optional :: comm, transfer_mode
    logical, allocatable :: tmp(:, :, :, :)
    call h5fort_read_lgc_4d(file_id, dset_path, tmp, hdferr, comm, transfer_mode)
    if (hdferr /= 0) return
    if (any(shape(tmp) /= shape(array))) then
      write(error_unit,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array)
      hdferr = -1; return
    end if
    array = tmp
  end subroutine h5fort_read_lgc_4d_fixed


end module h5fort_parallel_read_fixed
