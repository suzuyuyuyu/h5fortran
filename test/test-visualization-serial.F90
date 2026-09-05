program test_visualization_serial
  use hdf5
  use h5fort_serial_visualization, only: t_hdf5_writer
  use h5fort_serial_attribute, only: h5fort_read_attribute
#ifdef VISUALIZATION_EQUIVALENCE
  use h5fort_parallel_visualization, only: t_phdf5_writer
  use mpi
#endif
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none

  integer, parameter :: np = 5, nc = 2, npe = 3
  character(len=*), parameter :: path = 'test-visualization-serial.h5'
  type(t_hdf5_writer) :: writer
#ifdef VISUALIZATION_EQUIVALENCE
  type(t_phdf5_writer) :: parallel_writer
  integer :: mpi_err, nprocs
#endif
  integer(HID_T) :: file_id, dset_id, space_id
  integer(HSIZE_T) :: dims(2), maxdims(2)
  integer :: hdferr, rank, i
  integer(int32) :: scheme, cell_id(nc)
  integer(int64) :: connectivity(npe, nc), connectivity_read(npe, nc)
  real(real64) :: nodes(3, np), nodes_read(3, np)
  real(real64) :: pressure(np), velocity(3, np), velocity_read(3, np)
  real(real64) :: stress(6, np), stress_read(6, np)
  character(len=:), allocatable :: attribute_type

#ifdef VISUALIZATION_EQUIVALENCE
  call MPI_Init(mpi_err)
  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, mpi_err)
  call check(nprocs == 1, 'equivalence requires one rank')
#endif
  call delete_if_exists(path)
  call h5open_f(hdferr)
  call check(hdferr == 0, 'h5open_f failed')

  do i = 1, np
    nodes(:, i) = [real(10 * i + 1, real64), real(10 * i + 2, real64), real(10 * i + 3, real64)]
    pressure(i) = real(100 + 7 * i, real64)
    velocity(:, i) = [real(1000 + 11 * i, real64), real(2000 + 13 * i, real64), &
                      real(3000 + 17 * i, real64)]
    stress(:, i) = [real(1 + 10 * i, real64), real(2 + 20 * i, real64), &
                    real(3 + 30 * i, real64), real(4 + 40 * i, real64), &
                    real(5 + 50 * i, real64), real(6 + 60 * i, real64)]
  end do
  connectivity = reshape([0_int64, 2_int64, 4_int64, 1_int64, 3_int64, 0_int64], [npe, nc])
  cell_id = [73_int32, 149_int32]

  call write_fixture(writer, path)
#ifdef VISUALIZATION_EQUIVALENCE
  call delete_if_exists('test-visualization-equivalent.h5')
  call write_fixture(parallel_writer, 'test-visualization-equivalent.h5')
#endif

  call h5fopen_f(path, H5F_ACC_RDONLY_F, file_id, hdferr)
  call check(hdferr == 0, 'cannot reopen visualization file')
  call h5fort_read_attribute(file_id, '/', 'scheme_version', scheme, hdferr)
  call check(hdferr == 0 .and. scheme == 1_int32, 'scheme_version is not 1')

  call assert_shape(file_id, '/asymmetric/geometry/nodes', &
                   [int(3, HSIZE_T), int(np, HSIZE_T)])
  call assert_shape(file_id, '/asymmetric/geometry/connectivity', &
                   [int(npe, HSIZE_T), int(nc, HSIZE_T)])
  call assert_shape(file_id, '/asymmetric/point_data/Pressure', [int(np, HSIZE_T)])
  call assert_shape(file_id, '/asymmetric/point_data/Velocity', &
                   [int(3, HSIZE_T), int(np, HSIZE_T)])
  call assert_shape(file_id, '/asymmetric/point_data/Stress', &
                   [int(6, HSIZE_T), int(np, HSIZE_T)])
  call assert_shape(file_id, '/asymmetric/cell_data/CellID', [int(nc, HSIZE_T)])

  call h5fort_read_attribute(file_id, '/asymmetric/point_data/Pressure', &
                             'attribute_type', attribute_type, hdferr)
  call check(hdferr == 0 .and. trim(attribute_type) == 'Scalar', &
             'Pressure attribute_type is not Scalar')
  call h5fort_read_attribute(file_id, '/asymmetric/point_data/Velocity', &
                             'attribute_type', attribute_type, hdferr)
  call check(hdferr == 0 .and. trim(attribute_type) == 'Vector', &
             'Velocity attribute_type is not Vector')
  call h5fort_read_attribute(file_id, '/asymmetric/point_data/Stress', &
                             'attribute_type', attribute_type, hdferr)
  call check(hdferr == 0 .and. trim(attribute_type) == 'Tensor6', &
             'Stress attribute_type is not Tensor6')

  dims = [int(3, HSIZE_T), int(np, HSIZE_T)]
  call h5dopen_f(file_id, '/asymmetric/geometry/nodes', dset_id, hdferr)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, nodes_read, dims, hdferr)
  call h5dclose_f(dset_id, hdferr)
  call check(all(nodes_read == nodes), 'nodes dimension order or values are wrong')

  call h5dopen_f(file_id, '/asymmetric/geometry/connectivity', dset_id, hdferr)
  dims = [int(npe, HSIZE_T), int(nc, HSIZE_T)]
  call h5dread_f(dset_id, h5kind_to_type(int64, H5_INTEGER_KIND), connectivity_read, dims, hdferr)
  call h5dclose_f(dset_id, hdferr)
  call check(all(connectivity_read == connectivity), 'connectivity values are wrong')

  call h5dopen_f(file_id, '/asymmetric/point_data/Velocity', dset_id, hdferr)
  dims = [int(3, HSIZE_T), int(np, HSIZE_T)]
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, velocity_read, dims, hdferr)
  call h5dclose_f(dset_id, hdferr)
  call check(all(velocity_read == velocity), 'vector dimension order or values are wrong')

  call h5dopen_f(file_id, '/asymmetric/point_data/Stress', dset_id, hdferr)
  dims = [int(6, HSIZE_T), int(np, HSIZE_T)]
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, stress_read, dims, hdferr)
  call h5dclose_f(dset_id, hdferr)
  call check(all(stress_read == stress), 'Tensor6 component order or values are wrong')

  call h5fclose_f(file_id, hdferr)
  call h5close_f(hdferr)
#ifdef VISUALIZATION_EQUIVALENCE
  call MPI_Finalize(mpi_err)
#endif

contains

  subroutine write_fixture(writer, path)
    class(t_hdf5_writer), intent(inout) :: writer
    character(len=*), intent(in) :: path
    writer%h5_filepath = path
    writer%output_type = 'UnstructuredGrid'
    writer%mesh_name = 'asymmetric'
    writer%topology_type = 'Triangle'
    writer%nodes_per_element = npe
    writer%num_points = np
    writer%num_cells = nc
    writer%time = 0.5_real64
    call writer%init()
    call writer%write_geometry(nodes, connectivity)
    call writer%write_point_data(pressure, 'Pressure')
    call writer%write_point_data(velocity, 'Velocity')
    call writer%write_point_data(stress, 'Stress')
    call writer%write_cell_data(cell_id, 'CellID')
    call writer%close()
  end subroutine write_fixture

  subroutine assert_shape(file_id, dataset_path, expected)
    integer(HID_T), intent(in) :: file_id
    character(len=*), intent(in) :: dataset_path
    integer(HSIZE_T), intent(in) :: expected(:)
    integer(HID_T) :: dset_id, space_id
    integer(HSIZE_T) :: dims(2), maxdims(2)
    integer :: hdferr, rank

    call h5dopen_f(file_id, dataset_path, dset_id, hdferr)
    call check(hdferr == 0, 'missing dataset: ' // dataset_path)
    call h5dget_space_f(dset_id, space_id, hdferr)
    call h5sget_simple_extent_ndims_f(space_id, rank, hdferr)
    call check(rank == size(expected), 'wrong rank: ' // dataset_path)
    call h5sget_simple_extent_dims_f(space_id, dims(1:rank), maxdims(1:rank), hdferr)
    call check(all(dims(1:rank) == expected), 'wrong dimensions: ' // dataset_path)
    call h5sclose_f(space_id, hdferr)
    call h5dclose_f(dset_id, hdferr)
  end subroutine assert_shape

  subroutine check(condition, message)
    logical, intent(in) :: condition
    character(len=*), intent(in) :: message
    if (.not. condition) error stop message
  end subroutine check

  subroutine delete_if_exists(file_path)
    character(len=*), intent(in) :: file_path
    integer :: unit, ios
    open(newunit=unit, file=file_path, status='old', action='readwrite', iostat=ios)
    if (ios == 0) close(unit, status='delete')
  end subroutine delete_if_exists

end program test_visualization_serial
