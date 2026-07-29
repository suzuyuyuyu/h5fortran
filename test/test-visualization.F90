program test_visualization
  use hdf5, only: h5open_f, h5close_f
  use h5fort
  use mpi
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none

  integer, parameter :: np = 8, nc = 1
  type(t_phdf5_writer) :: ugrid, tetra, quadrilateral, triangle, particles
  integer :: ierr, hdferr, me, i
  real(real64) :: nodes(3, np), pressure(np), velocity(3, np)
  integer(int64) :: connectivity(8, nc)
  integer(int64) :: connectivity4(4, nc), connectivity3(3, nc)
  integer(int32) :: processor_id(nc)

  call MPI_Init(ierr)
  call h5open_f(hdferr)
  if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, me, ierr)
  if (me == 0) call delete_if_exists("test-visualization.h5")
  call MPI_Barrier(MPI_COMM_WORLD, ierr)

  do i = 1, np
    nodes(:, i) = [real(i + np * me, real64), real(me, real64), 0.0_real64]
    connectivity(i, 1) = int(i - 1, int64)
  end do
  connectivity4(:, 1) = connectivity(1:4, 1)
  connectivity3(:, 1) = connectivity(1:3, 1)
  pressure = real(me + 1, real64)
  velocity = real(me + 2, real64)
  processor_id = int(me, int32)

  ugrid%h5_filepath = "test-visualization.h5"
  ugrid%output_type = "UnstructuredGrid"
  ugrid%num_points = np
  ugrid%num_cells = nc
  ugrid%time = 0.25_real64
  call ugrid%init()
  call ugrid%write_geometry_ugrid(nodes, connectivity)
  call ugrid%write_point_data(pressure, "Pressure")
  call ugrid%write_point_data(velocity, "Velocity")
  call ugrid%write_cell_data(processor_id, "ProcessorID")
  call ugrid%close()

  tetra%h5_filepath = "test-visualization.h5"
  tetra%output_type = "UnstructuredGrid"
  tetra%mesh_name = "tetra"
  tetra%topology_type = "Tetrahedron"
  tetra%nodes_per_element = 4
  tetra%num_points = np
  tetra%num_cells = nc
  tetra%time = 0.25_real64
  call tetra%init()
  call tetra%write_geometry(nodes, connectivity4)
  call tetra%write_point_data(pressure, "Pressure")
  call tetra%close()

  quadrilateral%h5_filepath = "test-visualization.h5"
  quadrilateral%output_type = "UnstructuredGrid"
  quadrilateral%mesh_name = "quadrilateral"
  quadrilateral%topology_type = "Quadrilateral"
  quadrilateral%nodes_per_element = 4
  quadrilateral%num_points = np
  quadrilateral%num_cells = nc
  quadrilateral%time = 0.25_real64
  call quadrilateral%init()
  call quadrilateral%write_geometry(nodes, connectivity4)
  call quadrilateral%write_point_data(pressure, "Pressure")
  call quadrilateral%close()

  triangle%h5_filepath = "test-visualization.h5"
  triangle%output_type = "UnstructuredGrid"
  triangle%mesh_name = "triangle"
  triangle%topology_type = "Triangle"
  triangle%nodes_per_element = 3
  triangle%num_points = np
  triangle%num_cells = nc
  triangle%time = 0.25_real64
  call triangle%init()
  call triangle%write_geometry(nodes, connectivity3)
  call triangle%write_point_data(pressure, "Pressure")
  call triangle%close()

  particles%h5_filepath = "test-visualization.h5"
  particles%output_type = "PolyData"
  particles%num_points = np
  particles%num_cells = 0
  particles%time = 0.25_real64
  call particles%init()
  call particles%write_geometry_polydata(nodes)
  call particles%write_point_data(pressure, "Pressure")
  call particles%close()

  call h5close_f(hdferr)
  if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  call MPI_Finalize(ierr)

contains

  subroutine delete_if_exists(path)
    character(len=*), intent(in) :: path
    integer :: unit, ios
    open(newunit=unit, file=path, status="old", action="readwrite", iostat=ios)
    if (ios == 0) close(unit, status="delete")
  end subroutine delete_if_exists

end program test_visualization
