program test_xdmf
  use h5fort
  use mpi
  use, intrinsic :: iso_fortran_env, only: int8, int16, int32, int64, real32, real64, real128
  implicit none

  integer, parameter :: np = 8, nc = 1
  type(t_phdf5_writer) :: ug, pd
  integer :: ierr, me, i
  real(real32) :: nodes32(3, np), point_r32(np), cell_r32(nc)
  real(real64) :: nodes64(3, np), point_r64(np), point_vec(3, np), cell_r64(nc)
  real(real128) :: point_r128(np), cell_r128(nc)
  integer(int8) :: point_i8(np), cell_i8(nc)
  integer(int16) :: connectivity(8, nc), point_i16(np), cell_i16(nc)
  integer(int32) :: point_i32(np), cell_i32(nc), cell_vec(3, nc)
  integer(int64) :: point_i64(np), cell_i64(nc)

  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, me, ierr)
  if (me == 0) then
    call delete_if_exists('test-xdmf.h5')
    call delete_if_exists('seq00000_ugrid_phdf5.xdmf.part')
    call delete_if_exists('seq00000_polydata_phdf5.xdmf.part')
  end if
  call MPI_Barrier(MPI_COMM_WORLD, ierr)

  do i = 1, np
    nodes32(:, i) = [real(i + np * me, real32), real(me, real32), 0.0_real32]
    nodes64(:, i) = real(nodes32(:, i), real64)
    connectivity(i, 1) = int(np * me + i - 1, int16)
  end do
  point_i8 = int(me + 1, int8)
  point_i16 = int(me + 2, int16)
  point_i32 = int(me + 3, int32)
  point_i64 = int(me + 4, int64)
  point_r32 = real(me + 5, real32)
  point_r64 = real(me + 6, real64)
  point_r128 = real(me + 6, real128)
  point_vec = real(me + 7, real64)
  cell_i8 = int(me + 8, int8)
  cell_i16 = int(me + 9, int16)
  cell_i32 = int(me + 10, int32)
  cell_i64 = int(me + 11, int64)
  cell_r32 = real(me + 12, real32)
  cell_r64 = real(me + 13, real64)
  cell_r128 = real(me + 13, real128)
  cell_vec = int(me + 14, int32)

  ug%h5_filepath = 'test-xdmf.h5'
  ug%h5_filename = 'test-xdmf.h5'
  ug%metadata_dir = '.'
  ug%rel_dir_meta2h5 = '.'
  ug%output_type = 'UnstructuredGrid'
  ug%num_points = np
  ug%num_cells = nc
  ug%seq = 0
  ug%time = 0.25_real64
  call ug%init()
  call ug%write_geometry_ugrid(nodes32, connectivity)
  call ug%write_point_data(point_i8, 'point_i8')
  call ug%write_point_data(point_i16, 'point_i16')
  call ug%write_point_data(point_i32, 'point_i32')
  call ug%write_point_data(point_i64, 'point_i64')
  call ug%write_point_data(point_r32, 'point_r32')
  call ug%write_point_data(point_r64, 'point_r64')
  call ug%write_point_data(point_r128, 'point_r128')
  call ug%write_point_data(point_vec, 'point_vec')
  call ug%add_point_attr('point_r64')
  call ug%write_cell_data(cell_i8, 'cell_i8')
  call ug%write_cell_data(cell_i16, 'cell_i16')
  call ug%write_cell_data(cell_i32, 'cell_i32')
  call ug%write_cell_data(cell_i64, 'cell_i64')
  call ug%write_cell_data(cell_r32, 'cell_r32')
  call ug%write_cell_data(cell_r64, 'cell_r64')
  call ug%write_cell_data(cell_r128, 'cell_r128')
  call ug%write_cell_data(cell_vec, 'cell_vec')
  call ug%add_cell_attr('cell_i32')
  if (me == 0) call ug%write_fragment()
  call ug%close()

  ! The legacy real64 PolyData-specific binding remains available.
  pd%h5_filepath = 'test-xdmf.h5'
  pd%h5_filename = 'test-xdmf.h5'
  pd%metadata_dir = '.'
  pd%rel_dir_meta2h5 = '.'
  pd%output_type = 'PolyData'
  pd%num_points = np
  pd%num_cells = 0
  pd%seq = 0
  call pd%init()
  call pd%write_geometry_polydata(nodes64)
  if (me == 0) call pd%write_fragment()
  call pd%close()

  call MPI_Barrier(MPI_COMM_WORLD, ierr)
  if (me == 0) then
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'point_i8', 'Int', 1)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'point_i16', 'Int', 2)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'point_i32', 'Int', 4)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'point_i64', 'Int', 8)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'point_r32', 'Float', 4)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'point_r64', 'Float', 8)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'point_r128', 'Float', 16)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'cell_i8', 'Int', 1)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'cell_r64', 'Float', 8)
    call assert_fragment_attr('seq00000_ugrid_phdf5.xdmf.part', 'cell_r128', 'Float', 16)
    call assert_file_count('seq00000_ugrid_phdf5.xdmf.part', 'Attribute Name="point_r64"', 1)
    call assert_file_count('seq00000_ugrid_phdf5.xdmf.part', 'Attribute Name="cell_i32"', 1)
    call assert_file_contains('seq00000_ugrid_phdf5.xdmf.part', &
      'NumberType="Int" Precision="2" Dimensions="2 8"')
    call assert_file_contains('seq00000_ugrid_phdf5.xdmf.part', &
      'NumberType="Float" Precision="4" Dimensions="16 3"')
    call assert_file_contains('seq00000_polydata_phdf5.xdmf.part', 'TopologyType="Polyvertex"')
  end if

  call MPI_Finalize(ierr)

contains

  subroutine delete_if_exists(path)
    character(len=*), intent(in) :: path
    integer :: u, ios
    open(newunit=u, file=path, status='old', action='readwrite', iostat=ios)
    if (ios == 0) close(u, status='delete')
  end subroutine delete_if_exists

  subroutine assert_fragment_attr(path, name, num_type, precision)
    character(len=*), intent(in) :: path, name, num_type
    integer, intent(in) :: precision
    character(len=1024) :: line
    character(len=32) :: precision_text
    integer :: u, ios
    logical :: found_attr, found_type

    write(precision_text, '(a,i0,a)') 'Precision="', precision, '"'
    found_attr = .false.
    found_type = .false.
    open(newunit=u, file=path, status='old', action='read')
    do
      read(u, '(a)', iostat=ios) line
      if (ios /= 0) exit
      if (index(line, 'Attribute Name="' // trim(name) // '"') > 0) then
        found_attr = .true.
      else if (found_attr .and. index(line, '<DataItem') > 0) then
        found_type = index(line, 'NumberType="' // trim(num_type) // '"') > 0 .and. &
          index(line, trim(precision_text)) > 0
        exit
      end if
    end do
    close(u)
    call assert(found_attr .and. found_type, 'incorrect XDMF metadata for ' // trim(name))
  end subroutine assert_fragment_attr

  subroutine assert_file_contains(path, text)
    character(len=*), intent(in) :: path, text
    character(len=1024) :: line
    integer :: u, ios
    logical :: found

    found = .false.
    open(newunit=u, file=path, status='old', action='read')
    do
      read(u, '(a)', iostat=ios) line
      if (ios /= 0) exit
      if (index(line, text) > 0) then
        found = .true.
        exit
      end if
    end do
    close(u)
    call assert(found, 'missing fragment text: ' // trim(text))
  end subroutine assert_file_contains

  subroutine assert_file_count(path, text, expected)
    character(len=*), intent(in) :: path, text
    integer, intent(in) :: expected
    character(len=1024) :: line
    integer :: u, ios, count_

    count_ = 0
    open(newunit=u, file=path, status='old', action='read')
    do
      read(u, '(a)', iostat=ios) line
      if (ios /= 0) exit
      if (index(line, text) > 0) count_ = count_ + 1
    end do
    close(u)
    call assert(count_ == expected, 'unexpected occurrence count: ' // trim(text))
  end subroutine assert_file_count

  subroutine assert(ok, message)
    logical, intent(in) :: ok
    character(len=*), intent(in) :: message
    if (.not. ok) then
      write(*, '(2a)') 'assertion failed: ', message
      call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
    end if
  end subroutine assert

end program test_xdmf
