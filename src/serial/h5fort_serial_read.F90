#include "h5fort_serial.inc"
module h5fort_serial_read
  use hdf5
  use, intrinsic :: iso_fortran_env
  implicit none
  private

  public :: h5fort_read_r64_0d, h5fort_read_r64_1d, h5fort_read_r64_2d, h5fort_read_r64_3d, h5fort_read_r64_4d
  public :: h5fort_read_r32_0d, h5fort_read_r32_1d, h5fort_read_r32_2d, h5fort_read_r32_3d, h5fort_read_r32_4d
  public :: h5fort_read_i32_0d, h5fort_read_i32_1d, h5fort_read_i32_2d, h5fort_read_i32_3d, h5fort_read_i32_4d
  public :: h5fort_read_str_0d
  public :: h5fort_read_lgc_0d, h5fort_read_lgc_1d, h5fort_read_lgc_2d, h5fort_read_lgc_3d, h5fort_read_lgc_4d

contains
  !============================================================================
  ! マクロ的に各ランク・各型の実装を記述する
  ! （FortranにはC言語のようなマクロがないため手動で展開）
  !============================================================================

  !--------------------------------------------------------------------
  ! real64, scalar
  !--------------------------------------------------------------------
  subroutine h5fort_read_r64_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real64),     intent(out) :: scalar
    integer,          intent(out) :: hdferr

    integer(hid_t)   :: dset_id
    integer(hsize_t) :: dims(1)
    integer          :: err_local

    dims = [1_hsize_t]
    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) then
      write(*,'(A,A)') "[h5fort/serial/read] ERROR: h5dopen_f failed for: ", trim(dset_path)
      return
    end if
    call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, scalar, dims, hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r64_0d

  !--------------------------------------------------------------------
  ! real32, scalar
  !--------------------------------------------------------------------
  subroutine h5fort_read_r32_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    real(real32),     intent(out) :: scalar
    integer,          intent(out) :: hdferr

    integer(hid_t)   :: dset_id
    integer(hsize_t) :: dims(1)
    integer          :: err_local

    dims = [1_hsize_t]
    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) then
      write(*,'(A,A)') "[h5fort/serial/read] ERROR: h5dopen_f failed for: ", trim(dset_path)
      return
    end if
    call h5dread_f(dset_id, H5T_NATIVE_REAL, scalar, dims, hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r32_0d

  !--------------------------------------------------------------------
  ! int32, scalar
  !--------------------------------------------------------------------
  subroutine h5fort_read_i32_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    integer(int32),   intent(out) :: scalar
    integer,          intent(out) :: hdferr

    integer(hid_t)   :: dset_id
    integer(hsize_t) :: dims(1)
    integer          :: err_local

    dims = [1_hsize_t]
    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) then
      write(*,'(A,A)') "[h5fort/serial/read] ERROR: h5dopen_f failed for: ", trim(dset_path)
      return
    end if
    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, scalar, dims, hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_i32_0d

  !--------------------------------------------------------------------
  ! real64, 1D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r64_1d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real64), allocatable,  intent(out) :: array(:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 1) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-1."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1)))

    call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, array, dims(1:1), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r64_1d

  !--------------------------------------------------------------------
  ! real64, 2D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r64_2d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real64), allocatable,  intent(out) :: array(:,:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 2) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-2."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2)))

    call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, array, dims(1:2), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r64_2d

  !--------------------------------------------------------------------
  ! real64, 3D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r64_3d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real64), allocatable,  intent(out) :: array(:,:,:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 3) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-3."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2), dims(3)))

    call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, array, dims(1:3), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r64_3d

  !--------------------------------------------------------------------
  ! real64, 4D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r64_4d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real64), allocatable,  intent(out) :: array(:,:,:,:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 4) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-4."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2), dims(3), dims(4)))

    call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, array, dims(1:4), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r64_4d

  !--------------------------------------------------------------------
  ! real32, 1D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r32_1d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real32), allocatable,  intent(out) :: array(:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 1) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-1."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1)))

    call h5dread_f(dset_id, H5T_NATIVE_REAL, array, dims(1:1), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r32_1d

  !--------------------------------------------------------------------
  ! real32, 2D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r32_2d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real32), allocatable,  intent(out) :: array(:,:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 2) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-2."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2)))

    call h5dread_f(dset_id, H5T_NATIVE_REAL, array, dims(1:2), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r32_2d

  !--------------------------------------------------------------------
  ! real32, 3D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r32_3d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real32), allocatable,  intent(out) :: array(:,:,:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 3) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-3."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2), dims(3)))

    call h5dread_f(dset_id, H5T_NATIVE_REAL, array, dims(1:3), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r32_3d

  !--------------------------------------------------------------------
  ! real32, 4D
  !--------------------------------------------------------------------
  subroutine h5fort_read_r32_4d(file_id, dset_path, array, hdferr)
    integer(hid_t),             intent(in)  :: file_id
    character(len=*),           intent(in)  :: dset_path
    real(real32), allocatable,  intent(out) :: array(:,:,:,:)
    integer,                    intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 4) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-4."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2), dims(3), dims(4)))

    call h5dread_f(dset_id, H5T_NATIVE_REAL, array, dims(1:4), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_r32_4d

  !--------------------------------------------------------------------
  ! int32, 1D
  !--------------------------------------------------------------------
  subroutine h5fort_read_i32_1d(file_id, dset_path, array, hdferr)
    integer(hid_t),               intent(in)  :: file_id
    character(len=*),             intent(in)  :: dset_path
    integer(int32), allocatable,  intent(out) :: array(:)
    integer,                      intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 1) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-1."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1)))

    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, array, dims(1:1), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_i32_1d

  !--------------------------------------------------------------------
  ! int32, 2D
  !--------------------------------------------------------------------
  subroutine h5fort_read_i32_2d(file_id, dset_path, array, hdferr)
    integer(hid_t),               intent(in)  :: file_id
    character(len=*),             intent(in)  :: dset_path
    integer(int32), allocatable,  intent(out) :: array(:,:)
    integer,                      intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 2) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-2."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2)))

    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, array, dims(1:2), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_i32_2d

  !--------------------------------------------------------------------
  ! int32, 3D
  !--------------------------------------------------------------------
  subroutine h5fort_read_i32_3d(file_id, dset_path, array, hdferr)
    integer(hid_t),               intent(in)  :: file_id
    character(len=*),             intent(in)  :: dset_path
    integer(int32), allocatable,  intent(out) :: array(:,:,:)
    integer,                      intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 3) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-3."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2), dims(3)))

    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, array, dims(1:3), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_i32_3d

  !--------------------------------------------------------------------
  ! int32, 4D
  !--------------------------------------------------------------------
  subroutine h5fort_read_i32_4d(file_id, dset_path, array, hdferr)
    integer(hid_t),               intent(in)  :: file_id
    character(len=*),             intent(in)  :: dset_path
    integer(int32), allocatable,  intent(out) :: array(:,:,:,:)
    integer,                      intent(out) :: hdferr

    integer(hid_t)  :: dset_id
    integer         :: rank
    integer(hsize_t):: dims(MAX_RANK)
    integer         :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 4) then
      write(*,'(A,I0,A)') "[h5fort/serial/read] ERROR: dataset rank=", rank, &
                           " but target array is rank-4."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(array(dims(1), dims(2), dims(3), dims(4)))

    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, array, dims(1:4), hdferr)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_i32_4d

  !--------------------------------------------------------------------
  ! character, scalar (可変長文字列)
  !--------------------------------------------------------------------
  subroutine h5fort_read_str_0d(file_id, dset_path, str, hdferr)
    integer(hid_t),                intent(in)  :: file_id
    character(len=*),              intent(in)  :: dset_path
    character(len=:), allocatable, intent(out) :: str
    integer,                       intent(out) :: hdferr

    integer(hid_t)  :: dset_id, str_type_id
    integer(hsize_t):: dims(1)
    integer(size_t) :: str_len
    integer         :: err_local

    dims = [1_hsize_t]

    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) then
      write(*,'(A,A)') "[h5fort/serial/read] ERROR: h5dopen_f failed for: ", trim(dset_path)
      return
    end if

    call h5dget_type_f(dset_id, str_type_id, err_local)
    if (err_local /= 0) then
      hdferr = err_local
      call h5dclose_f(dset_id, err_local); return
    end if

    call h5tget_size_f(str_type_id, str_len, err_local)
    if (err_local /= 0) then
      hdferr = err_local
      call h5tclose_f(str_type_id, err_local); call h5dclose_f(dset_id, err_local); return
    end if

    allocate(character(len=str_len) :: str)
    call h5dread_f(dset_id, str_type_id, str, dims, hdferr)
    call h5tclose_f(str_type_id, err_local)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_str_0d

  !============================================================================
  ! logical (スカラー・配列): int32 (0/1) として HDF5 に保存・読込
  !============================================================================

  !--------------------------------------------------------------------
  ! logical, scalar – read
  !--------------------------------------------------------------------
  subroutine h5fort_read_lgc_0d(file_id, dset_path, scalar, hdferr)
    integer(hid_t),   intent(in)  :: file_id
    character(len=*), intent(in)  :: dset_path
    logical,          intent(out) :: scalar
    integer,          intent(out) :: hdferr

    integer(hid_t)   :: dset_id
    integer(hsize_t) :: dims(1)
    integer(int32)   :: ival
    integer          :: err_local

    dims = [1_hsize_t]
    call h5dopen_f(file_id, trim(dset_path), dset_id, hdferr)
    if (hdferr /= 0) then
      write(*,'(A,A)') "[h5fort_serial_write] ERROR: h5dopen_f failed for: ", trim(dset_path)
      return
    end if
    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, ival, dims, hdferr)
    scalar = (ival /= 0_int32)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_lgc_0d

  !--------------------------------------------------------------------
  ! logical, 1D – read
  !--------------------------------------------------------------------
  subroutine h5fort_read_lgc_1d(file_id, dset_path, array, hdferr)
    integer(hid_t),        intent(in)  :: file_id
    character(len=*),      intent(in)  :: dset_path
    logical, allocatable,  intent(out) :: array(:)
    integer,               intent(out) :: hdferr

    integer(hid_t)              :: dset_id
    integer                     :: rank
    integer(hsize_t)            :: dims(MAX_RANK)
    integer(int32), allocatable :: iarray(:)
    integer                     :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 1) then
      write(*,'(A,I0,A)') "[h5fort_serial_write] ERROR: dataset rank=", rank, &
                           " but target array is rank-1."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(iarray(dims(1)))
    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, iarray, dims(1:1), hdferr)
    allocate(array(dims(1)))
    array = (iarray /= 0_int32)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_lgc_1d

  !--------------------------------------------------------------------
  ! logical, 2D – read
  !--------------------------------------------------------------------
  subroutine h5fort_read_lgc_2d(file_id, dset_path, array, hdferr)
    integer(hid_t),        intent(in)  :: file_id
    character(len=*),      intent(in)  :: dset_path
    logical, allocatable,  intent(out) :: array(:,:)
    integer,               intent(out) :: hdferr

    integer(hid_t)              :: dset_id
    integer                     :: rank
    integer(hsize_t)            :: dims(MAX_RANK)
    integer(int32), allocatable :: iarray(:,:)
    integer                     :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 2) then
      write(*,'(A,I0,A)') "[h5fort_serial_write] ERROR: dataset rank=", rank, &
                           " but target array is rank-2."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(iarray(dims(1), dims(2)))
    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, iarray, dims(1:2), hdferr)
    allocate(array(dims(1), dims(2)))
    array = (iarray /= 0_int32)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_lgc_2d

  !--------------------------------------------------------------------
  ! logical, 3D – read
  !--------------------------------------------------------------------
  subroutine h5fort_read_lgc_3d(file_id, dset_path, array, hdferr)
    integer(hid_t),        intent(in)  :: file_id
    character(len=*),      intent(in)  :: dset_path
    logical, allocatable,  intent(out) :: array(:,:,:)
    integer,               intent(out) :: hdferr

    integer(hid_t)              :: dset_id
    integer                     :: rank
    integer(hsize_t)            :: dims(MAX_RANK)
    integer(int32), allocatable :: iarray(:,:,:)
    integer                     :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 3) then
      write(*,'(A,I0,A)') "[h5fort_serial_write] ERROR: dataset rank=", rank, &
                           " but target array is rank-3."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(iarray(dims(1), dims(2), dims(3)))
    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, iarray, dims(1:3), hdferr)
    allocate(array(dims(1), dims(2), dims(3)))
    array = (iarray /= 0_int32)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_lgc_3d

  !--------------------------------------------------------------------
  ! logical, 4D – read
  !--------------------------------------------------------------------
  subroutine h5fort_read_lgc_4d(file_id, dset_path, array, hdferr)
    integer(hid_t),        intent(in)  :: file_id
    character(len=*),      intent(in)  :: dset_path
    logical, allocatable,  intent(out) :: array(:,:,:,:)
    integer,               intent(out) :: hdferr

    integer(hid_t)              :: dset_id
    integer                     :: rank
    integer(hsize_t)            :: dims(MAX_RANK)
    integer(int32), allocatable :: iarray(:,:,:,:)
    integer                     :: err_local

    call get_dataset_info(file_id, dset_path, dset_id, rank, dims, hdferr)
    if (hdferr /= 0) return

    if (rank /= 4) then
      write(*,'(A,I0,A)') "[h5fort_serial_write] ERROR: dataset rank=", rank, &
                           " but target array is rank-4."
      hdferr = -1; call h5dclose_f(dset_id, err_local); return
    end if

    allocate(iarray(dims(1), dims(2), dims(3), dims(4)))
    call h5dread_f(dset_id, H5T_NATIVE_INTEGER, iarray, dims(1:4), hdferr)
    allocate(array(dims(1), dims(2), dims(3), dims(4)))
    array = (iarray /= 0_int32)
    call h5dclose_f(dset_id, err_local)
  end subroutine h5fort_read_lgc_4d

#include "h5fort_serial_read_utils.inc"
end module h5fort_serial_read
