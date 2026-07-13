<h1 align='center'> h5fortran </h1>

*h5fortran* is a Fortran library for reading and writing HDF5 files.
It provides a simple and efficient interface for working with HDF5 files in Fortran, supporting both Serial and Parallel HDF5.

## Requirements

- Intel Fortran (`ifx` / `mpiifx`)
- Parallel HDF5 with Fortran support (default path: `$HOME/.local/opt/intel/phdf5`, configurable via `H5FORTRAN_HDF5_ROOT`)

## Build & Install

```bash
cmake --preset intel-mpi -DCMAKE_INSTALL_PREFIX=$HOME/.local
cmake --build build/intel-mpi
cmake --install build/intel-mpi
```

## Quickstart

```fortran
program example
  use hdf5
  use h5fort
  use iso_fortran_env, only: real64
  implicit none

  integer :: hdferr
  integer(hid_t) :: file_id
  real(real64) :: data(100)
  real(real64), allocatable :: data_read(:)

  data = 1.0_real64

  call h5open_f(hdferr)

  call h5fcreate_f("out.h5", H5F_ACC_TRUNC_F, file_id, hdferr)
  call h5fort_swrite(file_id, "/data", data, hdferr)
  call h5fclose_f(file_id, hdferr)

  call h5fopen_f("out.h5", H5F_ACC_RDONLY_F, file_id, hdferr)
  call h5fort_sread(file_id, "/data", data_read, hdferr)
  call h5fclose_f(file_id, hdferr)

  call h5close_f(hdferr)
end program
```

## Downstream CMake Integration

After installing, downstream projects can link h5fortran via `find_package`:

```cmake
find_package(h5fortran REQUIRED)
target_link_libraries(my_target PRIVATE h5fortran::h5fortran)
```

For details on the full API, see [docs/USAGE.md](docs/USAGE.md).
