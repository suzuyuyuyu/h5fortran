

! DO NOT EDIT — generated from src/fypp/serial/h5fort_serial_visualization.fypp
! To regenerate: src/fypp/generate_fypp.sh

module h5fort_serial_visualization
  use h5fort_version, only: H5FORTRAN_SCHEME_VERSION
  use hdf5
  use, intrinsic :: iso_fortran_env
  implicit none
  private
  public :: t_hdf5_writer

  type :: t_hdf5_writer
    character(len=16) :: output_type = ''
    character(len=64) :: mesh_name = ''
    character(len=32) :: topology_type = ''
    integer :: nodes_per_element = 0
    character(len=:), allocatable :: h5_filepath

    integer(int64)    :: num_points  = 0_int64
    integer(int64)    :: num_cells   = 0_int64

    integer(int64), private :: total_points  = 0_int64
    integer(int64), private :: total_cells   = 0_int64
    integer(int64), private :: offset_points = 0_int64
    integer(int64), private :: offset_cells  = 0_int64

    integer(HID_T), private :: file_id   = -1
    integer(HID_T), private :: gid_geom  = -1
    integer(HID_T), private :: gid_pdata = -1
    integer(HID_T), private :: gid_cdata = -1
    integer(HID_T), private :: xfer_id   = -1

    real(real64)       :: time   = 0.0_real64

    logical, private :: initialized = .false.
  contains
    procedure :: initialize => hdf5_initialize
    procedure :: abort_writer => hdf5_abort
    procedure :: init  => hdf5_init
    procedure :: close => hdf5_close

    procedure :: write_geometry_ugrid_real32_int8 => hdf5_write_geom_ugrid_real32_int8
    procedure :: write_geometry_ugrid_real32_int16 => hdf5_write_geom_ugrid_real32_int16
    procedure :: write_geometry_ugrid_real32_int32 => hdf5_write_geom_ugrid_real32_int32
    procedure :: write_geometry_ugrid_real32_int64 => hdf5_write_geom_ugrid_real32_int64
    procedure :: write_geometry_polydata_real32 => hdf5_geom_polydata_real32
    procedure :: write_geometry_ugrid_real64_int8 => hdf5_write_geom_ugrid_real64_int8
    procedure :: write_geometry_ugrid_real64_int16 => hdf5_write_geom_ugrid_real64_int16
    procedure :: write_geometry_ugrid_real64_int32 => hdf5_write_geom_ugrid_real64_int32
    procedure :: write_geometry_ugrid_real64_int64 => hdf5_write_geom_ugrid_real64_int64
    procedure :: write_geometry_polydata_real64 => hdf5_geom_polydata_real64
    procedure :: write_geometry_ugrid_real128_int8 => hdf5_write_geom_ugrid_real128_int8
    procedure :: write_geometry_ugrid_real128_int16 => hdf5_write_geom_ugrid_real128_int16
    procedure :: write_geometry_ugrid_real128_int32 => hdf5_write_geom_ugrid_real128_int32
    procedure :: write_geometry_ugrid_real128_int64 => hdf5_write_geom_ugrid_real128_int64
    procedure :: write_geometry_polydata_real128 => hdf5_geom_polydata_real128
    procedure :: write_geometry_ugrid_i64 => hdf5_write_geom_ugrid_real64_int64
    procedure :: write_geometry_ugrid_i32 => hdf5_write_geom_ugrid_real64_int32
    procedure :: write_geometry_polydata  => hdf5_geom_polydata_real64
    generic   :: write_geometry_ugrid => &
      write_geometry_ugrid_real32_int8, &
      write_geometry_ugrid_real32_int16, &
      write_geometry_ugrid_real32_int32, &
      write_geometry_ugrid_real32_int64, &
      write_geometry_ugrid_real64_int8, &
      write_geometry_ugrid_real64_int16, &
      write_geometry_ugrid_real64_int32, &
      write_geometry_ugrid_real64_int64, &
      write_geometry_ugrid_real128_int8, &
      write_geometry_ugrid_real128_int16, &
      write_geometry_ugrid_real128_int32, &
      write_geometry_ugrid_real128_int64
    generic   :: write_geometry => &
      write_geometry_ugrid_real32_int8, &
      write_geometry_ugrid_real32_int16, &
      write_geometry_ugrid_real32_int32, &
      write_geometry_ugrid_real32_int64, &
      write_geometry_ugrid_real64_int8, &
      write_geometry_ugrid_real64_int16, &
      write_geometry_ugrid_real64_int32, &
      write_geometry_ugrid_real64_int64, &
      write_geometry_ugrid_real128_int8, &
      write_geometry_ugrid_real128_int16, &
      write_geometry_ugrid_real128_int32, &
      write_geometry_ugrid_real128_int64, &
      write_geometry_polydata_real32, &
      write_geometry_polydata_real64, &
      write_geometry_polydata_real128

    procedure :: write_point_1d_int8 => hdf5_point_1d_int8
    procedure :: write_cell_1d_int8  => hdf5_cell_1d_int8
    procedure :: write_point_2d_int8 => hdf5_point_2d_int8
    procedure :: write_cell_2d_int8  => hdf5_cell_2d_int8
    procedure :: write_point_1d_int16 => hdf5_point_1d_int16
    procedure :: write_cell_1d_int16  => hdf5_cell_1d_int16
    procedure :: write_point_2d_int16 => hdf5_point_2d_int16
    procedure :: write_cell_2d_int16  => hdf5_cell_2d_int16
    procedure :: write_point_1d_int32 => hdf5_point_1d_int32
    procedure :: write_cell_1d_int32  => hdf5_cell_1d_int32
    procedure :: write_point_2d_int32 => hdf5_point_2d_int32
    procedure :: write_cell_2d_int32  => hdf5_cell_2d_int32
    procedure :: write_point_1d_int64 => hdf5_point_1d_int64
    procedure :: write_cell_1d_int64  => hdf5_cell_1d_int64
    procedure :: write_point_2d_int64 => hdf5_point_2d_int64
    procedure :: write_cell_2d_int64  => hdf5_cell_2d_int64
    procedure :: write_point_1d_real32 => hdf5_point_1d_real32
    procedure :: write_cell_1d_real32  => hdf5_cell_1d_real32
    procedure :: write_point_2d_real32 => hdf5_point_2d_real32
    procedure :: write_cell_2d_real32  => hdf5_cell_2d_real32
    procedure :: write_point_1d_real64 => hdf5_point_1d_real64
    procedure :: write_cell_1d_real64  => hdf5_cell_1d_real64
    procedure :: write_point_2d_real64 => hdf5_point_2d_real64
    procedure :: write_cell_2d_real64  => hdf5_cell_2d_real64
    procedure :: write_point_1d_real128 => hdf5_point_1d_real128
    procedure :: write_cell_1d_real128  => hdf5_cell_1d_real128
    procedure :: write_point_2d_real128 => hdf5_point_2d_real128
    procedure :: write_cell_2d_real128  => hdf5_cell_2d_real128

    procedure :: write_point_1d => hdf5_point_1d_real64
    procedure :: write_point_2d => hdf5_point_2d_real64
    procedure :: write_cell_i32 => hdf5_cell_1d_int32
    generic   :: write_point_data => &
      write_point_1d_int8, &
      write_point_2d_int8, &
      write_point_1d_int16, &
      write_point_2d_int16, &
      write_point_1d_int32, &
      write_point_2d_int32, &
      write_point_1d_int64, &
      write_point_2d_int64, &
      write_point_1d_real32, &
      write_point_2d_real32, &
      write_point_1d_real64, &
      write_point_2d_real64, &
      write_point_1d_real128, &
      write_point_2d_real128
    generic   :: write_cell_data => &
      write_cell_1d_int8, &
      write_cell_2d_int8, &
      write_cell_1d_int16, &
      write_cell_2d_int16, &
      write_cell_1d_int32, &
      write_cell_2d_int32, &
      write_cell_1d_int64, &
      write_cell_2d_int64, &
      write_cell_1d_real32, &
      write_cell_2d_real32, &
      write_cell_1d_real64, &
      write_cell_2d_real64, &
      write_cell_1d_real128, &
      write_cell_2d_real128

  end type t_hdf5_writer

contains

  subroutine hdf5_init(self)
    class(t_hdf5_writer), intent(inout) :: self
    logical :: file_exists

    inquire(file=trim(self%h5_filepath), exist=file_exists)
    call self%initialize(H5P_DEFAULT_F, H5P_DEFAULT_F, file_exists, &
      self%num_points, self%num_cells, 0_int64, 0_int64)
  end subroutine hdf5_init

  subroutine hdf5_abort(self, code)
    class(t_hdf5_writer), intent(in) :: self
    integer, intent(in) :: code
    error stop code
  end subroutine hdf5_abort

  subroutine hdf5_initialize(self, fapl_id, xfer_id, file_exists, total_points, total_cells, offset_points, offset_cells)
    class(t_hdf5_writer), intent(inout) :: self
    integer(HID_T), intent(in) :: fapl_id, xfer_id
    logical, intent(in) :: file_exists
    integer(int64), intent(in) :: total_points, total_cells, offset_points, offset_cells
    integer(HID_T) :: gid_base
    integer :: hdferr

    if (self%initialized) then
      write(error_unit,'(a)') 'Visualization writer is already initialized'
      call self%abort_writer(2)
    end if
    self%initialized = .true.
    self%total_points = total_points
    self%total_cells = total_cells
    self%offset_points = offset_points
    self%offset_cells = offset_cells
    self%xfer_id = xfer_id

    select case (trim(self%output_type))
    case ('UnstructuredGrid', 'ugrid', 'unstructuredgrid', 'UGRID', 'vtu', 'VTU', 'Unstructured', 'unstructured')
      self%output_type = 'ugrid'
      if (len_trim(self%mesh_name) == 0) self%mesh_name = 'ugrid'
      if (len_trim(self%topology_type) == 0 .and. self%nodes_per_element == 0) then
        self%topology_type = 'Hexahedron'
        self%nodes_per_element = 8
      else if (len_trim(self%topology_type) == 0 .or. self%nodes_per_element <= 0) then
        write(error_unit,'(a)') 'ERROR hdf5_init: topology_type and nodes_per_element must be set together'
        call self%abort_writer(1)
      end if
    case ('PolyData', 'polydata', 'POLYDATA', 'vtp', 'VTP', 'PointData', 'pointdata', 'POINTDATA', 'Point', 'point')
      self%output_type = 'polydata'
      if (len_trim(self%mesh_name) == 0) self%mesh_name = 'polydata'
      self%topology_type = 'Polyvertex'
      self%nodes_per_element = 1
    case default
      write(error_unit,'(a)') 'ERROR hdf5_init: unknown output_type: ' // trim(self%output_type)
      call self%abort_writer(1)
    end select

    if (file_exists) then
      call h5fopen_f(trim(self%h5_filepath), H5F_ACC_RDWR_F, self%file_id, hdferr, access_prp=fapl_id)
    else
      call h5fcreate_f(trim(self%h5_filepath), H5F_ACC_TRUNC_F, self%file_id, hdferr, access_prp=fapl_id)
    end if

    if (hdferr /= 0) then
      write(error_unit,'(a,a)') 'ERROR hdf5_init: cannot open/create ', trim(self%h5_filepath)
      call self%abort_writer(1)
    end if

    if (.not. file_exists) then
      call write_int32_attribute_(self%file_id, 'scheme_version', &
                                 int(H5FORTRAN_SCHEME_VERSION, int32))
      call write_real64_attribute_(self%file_id, 'time', self%time)
    end if

    call h5gcreate_f(self%file_id, trim(self%mesh_name), gid_base, hdferr)

    call h5gcreate_f(gid_base, 'geometry',   self%gid_geom,  hdferr)
    call h5gcreate_f(gid_base, 'point_data', self%gid_pdata, hdferr)

    self%gid_cdata = -1
    if (trim(self%output_type) == 'ugrid') then
      call h5gcreate_f(gid_base, 'cell_data', self%gid_cdata, hdferr)
    end if
    call write_string_attribute_(gid_base, 'topology_type', trim(self%topology_type))
    call write_int32_attribute_(gid_base, 'nodes_per_element', int(self%nodes_per_element, int32))

    call h5gclose_f(gid_base, hdferr)

  end subroutine hdf5_initialize

  subroutine hdf5_close(self)
    class(t_hdf5_writer), intent(inout) :: self
    integer :: hdferr

    call h5gclose_f(self%gid_geom,  hdferr)
    call h5gclose_f(self%gid_pdata, hdferr)
    if (self%gid_cdata >= 0) call h5gclose_f(self%gid_cdata, hdferr)
    if (self%xfer_id /= H5P_DEFAULT_F) call h5pclose_f(self%xfer_id, hdferr)
    call h5fflush_f(self%file_id, H5F_SCOPE_GLOBAL_F, hdferr)
    call h5fclose_f(self%file_id, hdferr)

    self%file_id   = -1
    self%gid_geom  = -1
    self%gid_pdata = -1
    self%gid_cdata = -1
    self%xfer_id   = -1

    self%initialized = .false.
  end subroutine hdf5_close

  subroutine hdf5_write_geom_ugrid_real32_int8(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int8), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int8_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int8), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real32_int8

  subroutine hdf5_write_geom_ugrid_real32_int16(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int16), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int16_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int16), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real32_int16

  subroutine hdf5_write_geom_ugrid_real32_int32(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int32), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int32_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int32), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real32_int32

  subroutine hdf5_write_geom_ugrid_real32_int64(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32),   intent(in) :: nodes(:, :)
    integer(int64), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int64_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int64), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real32_int64

  subroutine hdf5_geom_polydata_real32(self, nodes)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: nodes(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
    call write_slab_real32_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)
  end subroutine hdf5_geom_polydata_real32

  subroutine hdf5_write_geom_ugrid_real64_int8(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int8), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int8_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int8), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real64_int8

  subroutine hdf5_write_geom_ugrid_real64_int16(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int16), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int16_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int16), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real64_int16

  subroutine hdf5_write_geom_ugrid_real64_int32(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int32), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int32_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int32), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real64_int32

  subroutine hdf5_write_geom_ugrid_real64_int64(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64),   intent(in) :: nodes(:, :)
    integer(int64), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int64_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int64), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real64_int64

  subroutine hdf5_geom_polydata_real64(self, nodes)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: nodes(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
    call write_slab_real64_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)
  end subroutine hdf5_geom_polydata_real64

  subroutine hdf5_write_geom_ugrid_real128_int8(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int8), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int8_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int8), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real128_int8

  subroutine hdf5_write_geom_ugrid_real128_int16(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int16), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int16_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int16), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real128_int16

  subroutine hdf5_write_geom_ugrid_real128_int32(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int32), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int32_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int32), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real128_int32

  subroutine hdf5_write_geom_ugrid_real128_int64(self, nodes, connectivity)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128),   intent(in) :: nodes(:, :)
    integer(int64), intent(in) :: connectivity(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [int(self%nodes_per_element, int64), self%num_cells])
    if (rank(connectivity) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(connectivity, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `connectivity` has incorrect shape"
      end if
    end do
  end associate
end block
    if (size(connectivity) > 0) then
      if (minval(int(connectivity, int64)) < 0_int64 .or. &
          maxval(int(connectivity, int64)) >= self%num_points) then
        error stop "[h5fortran/VISUALIZATION] connectivity contains an out-of-range local node ID"
      end if
    end if
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)

    call write_slab_int64_2d_(self%gid_geom, 'connectivity', &
      [int(self%nodes_per_element, int64), self%num_cells], &
      self%offset_cells, self%total_cells, &
      connectivity + int(self%offset_points, int64), self%xfer_id)
  end subroutine hdf5_write_geom_ugrid_real128_int64

  subroutine hdf5_geom_polydata_real128(self, nodes)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: nodes(:, :)

block
  integer :: check_shape_d__

  associate(check_shape_expected__ => [3_int64, self%num_points])
    if (rank(nodes) /= size(check_shape_expected__)) then
      error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
    end if

    do check_shape_d__ = 1, size(check_shape_expected__)
      if (size(nodes, dim=check_shape_d__) /= check_shape_expected__(check_shape_d__)) then
        error stop "[h5fortran/VISUALIZATION] Array `nodes` has incorrect shape"
      end if
    end do
  end associate
end block
    call write_slab_real128_2d_(self%gid_geom, 'nodes', &
      [3_int64, self%num_points], self%offset_points, self%total_points, nodes, self%xfer_id)
  end subroutine hdf5_geom_polydata_real128


  subroutine hdf5_point_1d_int8(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int8_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine hdf5_point_1d_int8

  subroutine hdf5_cell_1d_int8(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_1d_int8: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int8_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine hdf5_cell_1d_int8

  subroutine hdf5_point_2d_int8(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int8_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine hdf5_point_2d_int8

  subroutine hdf5_cell_2d_int8(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int8), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_2d_int8: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int8_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine hdf5_cell_2d_int8

  subroutine hdf5_point_1d_int16(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int16_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine hdf5_point_1d_int16

  subroutine hdf5_cell_1d_int16(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_1d_int16: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int16_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine hdf5_cell_1d_int16

  subroutine hdf5_point_2d_int16(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int16_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine hdf5_point_2d_int16

  subroutine hdf5_cell_2d_int16(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int16), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_2d_int16: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int16_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine hdf5_cell_2d_int16

  subroutine hdf5_point_1d_int32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int32_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine hdf5_point_1d_int32

  subroutine hdf5_cell_1d_int32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_1d_int32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int32_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine hdf5_cell_1d_int32

  subroutine hdf5_point_2d_int32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int32_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine hdf5_point_2d_int32

  subroutine hdf5_cell_2d_int32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int32), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_2d_int32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int32_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine hdf5_cell_2d_int32

  subroutine hdf5_point_1d_int64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int64_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine hdf5_point_1d_int64

  subroutine hdf5_cell_1d_int64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_1d_int64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int64_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine hdf5_cell_1d_int64

  subroutine hdf5_point_2d_int64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_int64_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine hdf5_point_2d_int64

  subroutine hdf5_cell_2d_int64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    integer(int64), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_2d_int64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_int64_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine hdf5_cell_2d_int64

  subroutine hdf5_point_1d_real32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real32_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine hdf5_point_1d_real32

  subroutine hdf5_cell_1d_real32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_1d_real32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real32_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine hdf5_cell_1d_real32

  subroutine hdf5_point_2d_real32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real32_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine hdf5_point_2d_real32

  subroutine hdf5_cell_2d_real32(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real32), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_2d_real32: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real32_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine hdf5_cell_2d_real32

  subroutine hdf5_point_1d_real64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real64_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine hdf5_point_1d_real64

  subroutine hdf5_cell_1d_real64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_1d_real64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real64_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine hdf5_cell_1d_real64

  subroutine hdf5_point_2d_real64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real64_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine hdf5_point_2d_real64

  subroutine hdf5_cell_2d_real64(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real64), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_2d_real64: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real64_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine hdf5_cell_2d_real64

  subroutine hdf5_point_1d_real128(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 1), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real128_1d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, 1)
  end subroutine hdf5_point_1d_real128

  subroutine hdf5_cell_1d_real128(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_1d_real128: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 1), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real128_1d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, 1)

  end subroutine hdf5_cell_1d_real128

  subroutine hdf5_point_2d_real128(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:, :)
    character(len=*), intent(in) :: field_name

    if (int(size(data, 2), int64) /= self%num_points) then
      error stop "[h5fortran/VISUALIZATION] point-data size does not match num_points"
    end if
    call write_slab_real128_2d_(&
      self%gid_pdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_points, self%total_points, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_pdata, field_name, size(data, 1))
  end subroutine hdf5_point_2d_real128

  subroutine hdf5_cell_2d_real128(self, data, field_name)
    class(t_hdf5_writer), intent(inout) :: self
    real(real128), intent(in) :: data(:, :)
    character(len=*),  intent(in) :: field_name

    if (self%gid_cdata < 0) then
      write(error_unit,'(a)') 'ERROR hdf5_cell_2d_real128: cell_data group not open'
      stop 1
    end if
    if (int(size(data, 2), int64) /= self%num_cells) then
      error stop "[h5fortran/VISUALIZATION] cell-data size does not match num_cells"
    end if

    call write_slab_real128_2d_(&
      self%gid_cdata, trim(field_name), &
      [int(size(data, 1), int64), int(size(data, 2), int64)], &
      self%offset_cells, self%total_cells, &
      data, self%xfer_id&
    )
    call write_field_metadata_(self%gid_cdata, field_name, size(data, 1))

  end subroutine hdf5_cell_2d_real128


  subroutine write_slab_int8_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int8), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int8, H5_integer_KIND)

    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int8_1d_

  subroutine write_slab_int8_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int8), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int8, H5_integer_KIND)

    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int8_2d_

  subroutine write_slab_int16_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int16), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int16, H5_integer_KIND)

    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int16_1d_

  subroutine write_slab_int16_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int16), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int16, H5_integer_KIND)

    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int16_2d_

  subroutine write_slab_int32_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int32), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int32, H5_integer_KIND)

    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int32_1d_

  subroutine write_slab_int32_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int32), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int32, H5_integer_KIND)

    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int32_2d_

  subroutine write_slab_int64_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    integer(int64), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int64, H5_integer_KIND)

    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int64_1d_

  subroutine write_slab_int64_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    integer(int64), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(int64, H5_integer_KIND)

    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_int64_2d_

  subroutine write_slab_real32_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    real(real32), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real32, H5_real_KIND)

    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real32_1d_

  subroutine write_slab_real32_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    real(real32), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real32, H5_real_KIND)

    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real32_2d_

  subroutine write_slab_real64_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    real(real64), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real64, H5_real_KIND)

    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real64_1d_

  subroutine write_slab_real64_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    real(real64), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real64, H5_real_KIND)

    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real64_2d_

  subroutine write_slab_real128_1d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(1)
    integer(int64),     intent(in) :: offset, n_total
    real(real128), intent(in) :: data(:)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(1), dims_m(1), hstart(1), hcount(1)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real128, H5_real_KIND)

    dims_f(1) = int(n_total, HSIZE_T)

    call h5screate_simple_f(1, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(max(dims(1), 1_int64), HSIZE_T)
    if (dims(1) > 0_int64) then
      hstart(1) = int(offset, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      dims_m(1) = int(dims(1), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(1, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real128_1d_

  subroutine write_slab_real128_2d_(gid, dname, dims, offset, n_total, data, xfer_id)
    integer(HID_T),     intent(in) :: gid, xfer_id
    character(len=*),   intent(in) :: dname
    integer(int64),     intent(in) :: dims(2)
    integer(int64),     intent(in) :: offset, n_total
    real(real128), intent(in) :: data(:, :)
    integer :: hdferr
    integer(HID_T)   :: fsid, msid, did
    integer(HSIZE_T) :: dims_f(2), dims_m(2), hstart(2), hcount(2)
    integer(HID_T)   :: h5t_native_kind

    h5t_native_kind = h5kind_to_type(real128, H5_real_KIND)

    dims_f(1) = int(dims(1), HSIZE_T)
    dims_f(2) = int(n_total, HSIZE_T)

    call h5screate_simple_f(2, dims_f, fsid, hdferr)
    call h5dcreate_f(gid, dname, h5t_native_kind, fsid, did, hdferr)

    dims_m(1) = int(dims(1), HSIZE_T)
    dims_m(2) = int(max(dims(2), 1_int64), HSIZE_T)
    if (dims(2) > 0_int64) then
      hstart(1) = int(0, HSIZE_T)
      hcount(1) = int(dims(1), HSIZE_T)
      hstart(2) = int(offset, HSIZE_T)
      hcount(2) = int(dims(2), HSIZE_T)
      dims_m(2) = int(dims(2), HSIZE_T)
      call h5sselect_hyperslab_f(fsid, H5S_SELECT_SET_F, hstart, hcount, hdferr)
      call h5screate_simple_f(2, dims_m, msid, hdferr)
    else
      call h5sselect_none_f(fsid, hdferr)
      call h5screate_f(H5S_NULL_F, msid, hdferr)
    end if

    call h5dwrite_f(&
      did, h5t_native_kind, data, dims_m, hdferr, &
      mem_space_id=msid, &
      file_space_id=fsid, &
      xfer_prp=xfer_id &
    )
    call h5dclose_f(did, hdferr)
    call h5sclose_f(fsid, hdferr)
    call h5sclose_f(msid, hdferr)
  end subroutine write_slab_real128_2d_


  subroutine write_field_metadata_(gid, field_name, ncomp)
    integer(HID_T), intent(in) :: gid
    character(len=*), intent(in) :: field_name
    integer, intent(in) :: ncomp
    integer(HID_T) :: did
    integer :: hdferr
    character(len=16) :: attribute_type

    select case (ncomp)
    case (1)
      attribute_type = 'Scalar'
    case (3)
      attribute_type = 'Vector'
    case (6)
      attribute_type = 'Tensor6'
    case (9)
      attribute_type = 'Tensor'
    case default
      error stop "[h5fortran/visualization] ncomp must be 1, 3, 6, or 9"
    end select

    call h5dopen_f(gid, trim(field_name), did, hdferr)
    if (hdferr /= 0) error stop "[h5fortran/visualization] cannot open field dataset"
    call write_string_attribute_(did, 'attribute_type', trim(attribute_type))
    call h5dclose_f(did, hdferr)
  end subroutine write_field_metadata_

  subroutine write_string_attribute_(obj_id, name, value)
    integer(HID_T), intent(in) :: obj_id
    character(len=*), intent(in) :: name, value
    integer(HID_T) :: aid, sid, tid
    integer(HSIZE_T) :: dims(1)
    integer(SIZE_T) :: value_len
    integer :: hdferr

    dims = [1_HSIZE_T]
    value_len = max(1_SIZE_T, int(len_trim(value), SIZE_T))
    call h5tcopy_f(H5T_FORTRAN_S1, tid, hdferr)
    call h5tset_size_f(tid, value_len, hdferr)
    call h5screate_f(H5S_SCALAR_F, sid, hdferr)
    call h5acreate_f(obj_id, trim(name), tid, sid, aid, hdferr)
    call h5awrite_f(aid, tid, value, dims, hdferr)
    call h5aclose_f(aid, hdferr)
    call h5sclose_f(sid, hdferr)
    call h5tclose_f(tid, hdferr)
  end subroutine write_string_attribute_

  subroutine write_int32_attribute_(obj_id, name, value)
    integer(HID_T), intent(in) :: obj_id
    character(len=*), intent(in) :: name
    integer(int32), intent(in) :: value
    integer(HID_T) :: aid, sid, tid
    integer(HSIZE_T) :: dims(1)
    integer :: hdferr

    dims = [1_HSIZE_T]
    tid = h5kind_to_type(int32, H5_INTEGER_KIND)
    call h5screate_f(H5S_SCALAR_F, sid, hdferr)
    call h5acreate_f(obj_id, trim(name), tid, sid, aid, hdferr)
    call h5awrite_f(aid, tid, value, dims, hdferr)
    call h5aclose_f(aid, hdferr)
    call h5sclose_f(sid, hdferr)
  end subroutine write_int32_attribute_

  subroutine write_real64_attribute_(obj_id, name, value)
    integer(HID_T), intent(in) :: obj_id
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value
    integer(HID_T) :: aid, sid, tid
    integer(HSIZE_T) :: dims(1)
    integer :: hdferr

    dims = [1_HSIZE_T]
    tid = h5kind_to_type(real64, H5_REAL_KIND)
    call h5screate_f(H5S_SCALAR_F, sid, hdferr)
    call h5acreate_f(obj_id, trim(name), tid, sid, aid, hdferr)
    call h5awrite_f(aid, tid, value, dims, hdferr)
    call h5aclose_f(aid, hdferr)
    call h5sclose_f(sid, hdferr)
  end subroutine write_real64_attribute_

end module h5fort_serial_visualization
