add_library(h5fortran_serial
  serial/h5fort_serial_write.F90
  serial/h5fort_serial_read.F90
  serial/h5fort_serial_read_fixed.F90
  serial/h5fort_serial.F90)

set(H5FORTRAN_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/mod")
file(MAKE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")
target_link_libraries(h5fortran_serial PUBLIC h5fortran_hdf5)
target_include_directories(h5fortran_serial PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/serial"
  "${H5FORTRAN_MODULE_DIRECTORY}")
set_target_properties(h5fortran_serial PROPERTIES
  Fortran_PREPROCESS ON
  Fortran_MODULE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")

add_library(h5fortran_parallel
  parallel/h5fort_parallel_write.F90
  parallel/h5fort_parallel_read.F90
  parallel/h5fort_parallel_read_fixed.F90
  parallel/h5fort_parallel_hdf5_xdmf.F90
  parallel/h5fort_parallel.F90)

target_link_libraries(h5fortran_parallel PUBLIC h5fortran_hdf5)
target_include_directories(h5fortran_parallel PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/parallel"
  "${H5FORTRAN_MODULE_DIRECTORY}")
set_target_properties(h5fortran_parallel PROPERTIES
  Fortran_PREPROCESS ON
  Fortran_MODULE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")

add_library(h5fortran
  h5fort.F90)

target_link_libraries(h5fortran PUBLIC
  h5fortran_serial
  h5fortran_parallel
  h5fortran_hdf5)
target_include_directories(h5fortran PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${H5FORTRAN_MODULE_DIRECTORY}")
set_target_properties(h5fortran PROPERTIES
  Fortran_PREPROCESS ON
  Fortran_MODULE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")
