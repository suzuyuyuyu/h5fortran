program write_visualization_results
  use hdf5, only: h5open_f, h5close_f
  use h5fort
  use mpi
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none

  integer, parameter :: num_steps = 5
  integer, parameter :: fluid_nx = 4, fluid_ny = 4, fluid_nz = 3
  integer, parameter :: fluid_points = (fluid_nx + 1) * (fluid_ny + 1) * (fluid_nz + 1)
  integer, parameter :: fluid_cells = 6 * fluid_nx * fluid_ny * fluid_nz
  integer, parameter :: soil_nx = 4, soil_ny = 4, soil_nz = 3
  integer, parameter :: max_soil_particles = soil_nx * soil_ny * soil_nz
  real(real64), parameter :: pi = acos(-1.0_real64)

  type(t_phdf5_writer) :: fluid, soil
  integer :: ierr, hdferr, me, nprocs, step, i, ix, iy, iz, cell, num_soil_particles
  integer :: vertices(8), tetrahedra(4, 6)
  character(len=256) :: filename
  real(real64) :: time, x, y, z, x0, y0, z0, xc, yc, radius, phase
  real(real64) :: fluid_nodes(3, fluid_points)
  real(real64) :: pressure(fluid_points), velocity(3, fluid_points), speed(fluid_points)
  integer(int64) :: fluid_connectivity(4, fluid_cells)
  integer(int32) :: subdomain_id(fluid_cells)
  real(real64), allocatable :: particle_nodes(:, :), particle_velocity(:, :)
  real(real64), allocatable :: particle_stress(:)
  integer(int64), allocatable :: particle_id(:)

  call MPI_Init(ierr)
  call h5open_f(hdferr)
  if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, me, ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

  if (me == 0) call execute_command_line("mkdir -p result")
  call MPI_Barrier(MPI_COMM_WORLD, ierr)

  call make_fluid_mesh(me, fluid_nodes, fluid_connectivity)
  subdomain_id = int(me, int32)
  xc = 0.5_real64 * real(fluid_nx * nprocs, real64)
  yc = 0.5_real64 * real(fluid_ny, real64)

  do step = 0, num_steps - 1
    write(filename, '("result/seq",i6.6,".h5")') step
    time = 0.25_real64 * real(step, real64)

    if (me == 0) call delete_if_exists(trim(filename))
    call MPI_Barrier(MPI_COMM_WORLD, ierr)

    ! A travelling pressure wave combined with a time-modulated vortex.
    do i = 1, fluid_points
      x = fluid_nodes(1, i)
      y = fluid_nodes(2, i)
      z = fluid_nodes(3, i)
      phase = 2.0_real64 * pi * (x / real(fluid_nx * nprocs, real64) - 0.35_real64 * time)
      pressure(i) = 1000.0_real64 * (real(fluid_nz, real64) - z) + &
        180.0_real64 * sin(phase) * cos(pi * y / real(fluid_ny, real64))
      velocity(1, i) = -0.18_real64 * (y - yc) * cos(2.0_real64 * pi * 0.2_real64 * time)
      velocity(2, i) =  0.18_real64 * (x - xc) * cos(2.0_real64 * pi * 0.2_real64 * time)
      velocity(3, i) =  0.12_real64 * sin(phase) * sin(pi * z / real(fluid_nz, real64))
      speed(i) = sqrt(sum(velocity(:, i)**2))
    end do

    fluid%h5_filepath = trim(filename)
    fluid%output_type = "UnstructuredGrid"
    fluid%mesh_name = "fluid"
    fluid%topology_type = "Tetrahedron"
    fluid%nodes_per_element = 4
    fluid%num_points = fluid_points
    fluid%num_cells = fluid_cells
    fluid%time = time
    call fluid%init()
    call fluid%write_geometry(fluid_nodes, fluid_connectivity)
    call fluid%write_point_data(pressure, "Pressure")
    call fluid%write_point_data(velocity, "Velocity")
    call fluid%write_point_data(speed, "Speed")
    call fluid%write_cell_data(subdomain_id, "SubdomainID")
    call fluid%close()

    ! A granular layer settles and spreads radially.  A few particles leave the
    ! domain at each step, demonstrating variable entity counts.
    num_soil_particles = max(1, max_soil_particles - 2 * step - me)
    allocate(particle_nodes(3, num_soil_particles))
    allocate(particle_velocity(3, num_soil_particles))
    allocate(particle_stress(num_soil_particles))
    allocate(particle_id(num_soil_particles))
    do i = 1, num_soil_particles
      ix = modulo(i - 1, soil_nx)
      iy = modulo((i - 1) / soil_nx, soil_ny)
      iz = (i - 1) / (soil_nx * soil_ny)
      x0 = real(me * soil_nx + ix, real64) + 0.5_real64
      y0 = real(iy, real64) + 0.5_real64
      z0 = 2.15_real64 + 0.32_real64 * real(iz, real64)
      radius = sqrt((x0 - xc)**2 + (y0 - yc)**2)

      particle_velocity(1, i) =  0.12_real64 * (x0 - xc)
      particle_velocity(2, i) =  0.12_real64 * (y0 - yc)
      particle_velocity(3, i) = -(0.65_real64 + 0.07_real64 * radius)
      particle_nodes(1, i) = x0 + time * particle_velocity(1, i)
      particle_nodes(2, i) = y0 + time * particle_velocity(2, i)
      particle_nodes(3, i) = max(0.15_real64, z0 + time * particle_velocity(3, i))
      particle_stress(i) = 5.0_real64 + &
        14.0_real64 * (real(fluid_nz, real64) - particle_nodes(3, i))
      particle_id(i) = int(max_soil_particles * me + i, int64)
    end do

    soil%h5_filepath = trim(filename)
    soil%output_type = "PolyData"
    soil%mesh_name = "soil_particles"
    soil%num_points = num_soil_particles
    soil%num_cells = 0
    soil%time = time
    call soil%init()
    call soil%write_geometry(particle_nodes)
    call soil%write_point_data(particle_velocity, "Velocity")
    call soil%write_point_data(particle_stress, "EquivalentStress")
    call soil%write_point_data(particle_id, "ParticleID")
    call soil%close()

    deallocate(particle_nodes, particle_velocity, particle_stress, particle_id)
  end do

  call h5close_f(hdferr)
  if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  call MPI_Finalize(ierr)

contains

  subroutine make_fluid_mesh(rank, nodes, connectivity)
    integer, intent(in) :: rank
    real(real64), intent(out) :: nodes(3, fluid_points)
    integer(int64), intent(out) :: connectivity(4, fluid_cells)
    integer :: local_node, t

    do iz = 0, fluid_nz
      do iy = 0, fluid_ny
        do ix = 0, fluid_nx
          local_node = node_index(ix, iy, iz)
          nodes(:, local_node) = [real(rank * fluid_nx + ix, real64), &
            real(iy, real64), real(iz, real64)]
        end do
      end do
    end do

    ! Six tetrahedra around the v000-v111 body diagonal exactly fill one cube.
    tetrahedra(:, 1) = [1, 2, 4, 8]
    tetrahedra(:, 2) = [1, 4, 3, 8]
    tetrahedra(:, 3) = [1, 3, 7, 8]
    tetrahedra(:, 4) = [1, 7, 5, 8]
    tetrahedra(:, 5) = [1, 5, 6, 8]
    tetrahedra(:, 6) = [1, 6, 2, 8]

    cell = 0
    do iz = 0, fluid_nz - 1
      do iy = 0, fluid_ny - 1
        do ix = 0, fluid_nx - 1
          vertices = [ &
            node_index(ix,     iy,     iz), &
            node_index(ix + 1, iy,     iz), &
            node_index(ix,     iy + 1, iz), &
            node_index(ix + 1, iy + 1, iz), &
            node_index(ix,     iy,     iz + 1), &
            node_index(ix + 1, iy,     iz + 1), &
            node_index(ix,     iy + 1, iz + 1), &
            node_index(ix + 1, iy + 1, iz + 1) ]
          do t = 1, 6
            cell = cell + 1
            connectivity(:, cell) = int(vertices(tetrahedra(:, t)) - 1, int64)
          end do
        end do
      end do
    end do
  end subroutine make_fluid_mesh

  integer function node_index(ix_in, iy_in, iz_in)
    integer, intent(in) :: ix_in, iy_in, iz_in

    node_index = 1 + ix_in + (fluid_nx + 1) * (iy_in + (fluid_ny + 1) * iz_in)
  end function node_index

  subroutine delete_if_exists(path)
    character(len=*), intent(in) :: path
    integer :: unit, ios

    open(newunit=unit, file=path, status="old", action="readwrite", iostat=ios)
    if (ios == 0) close(unit, status="delete")
  end subroutine delete_if_exists

end program write_visualization_results
