set(H5FORTRAN_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/mod")
file(MAKE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")

set(h5fortran_components h5fortran_hdf5)

if(H5FORTRAN_ENABLE_SERIAL)
  add_library(h5fortran_serial
    serial/h5fort_serial_write.F90
    serial/h5fort_serial_read.F90
    serial/h5fort_serial_read_fixed.F90
    serial/h5fort_serial.F90)
  target_link_libraries(h5fortran_serial PUBLIC h5fortran_hdf5)
  target_include_directories(h5fortran_serial
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/serial"
    PUBLIC
      "$<BUILD_INTERFACE:${H5FORTRAN_MODULE_DIRECTORY}>"
      "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/h5fortran>")
  set_target_properties(h5fortran_serial PROPERTIES
    Fortran_PREPROCESS ON
    Fortran_MODULE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")
  list(APPEND h5fortran_components h5fortran_serial)
endif()

if(H5FORTRAN_ENABLE_PARALLEL)
  add_library(h5fortran_parallel
    parallel/h5fort_parallel_write.F90
    parallel/h5fort_parallel_read.F90
    parallel/h5fort_parallel_read_fixed.F90
    parallel/h5fort_parallel_hdf5_xdmf.F90
    parallel/h5fort_parallel.F90)
  target_link_libraries(h5fortran_parallel PUBLIC h5fortran_hdf5 MPI::MPI_Fortran)
  target_include_directories(h5fortran_parallel
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/parallel"
    PUBLIC
      "$<BUILD_INTERFACE:${H5FORTRAN_MODULE_DIRECTORY}>"
      "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/h5fortran>")
  set_target_properties(h5fortran_parallel PROPERTIES
    Fortran_PREPROCESS ON
    Fortran_MODULE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")
  list(APPEND h5fortran_components h5fortran_parallel)
endif()

add_library(h5fortran
  h5fort.F90)

target_link_libraries(h5fortran PUBLIC ${h5fortran_components})
target_include_directories(h5fortran
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}"
  PUBLIC
    "$<BUILD_INTERFACE:${H5FORTRAN_MODULE_DIRECTORY}>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/h5fortran>")
if(H5FORTRAN_ENABLE_SERIAL)
  target_compile_definitions(h5fortran PRIVATE H5FORTRAN_SERIAL)
endif()
if(H5FORTRAN_ENABLE_PARALLEL)
  target_compile_definitions(h5fortran PRIVATE H5FORTRAN_PARALLEL)
endif()
set_target_properties(h5fortran PROPERTIES
  Fortran_PREPROCESS ON
  Fortran_MODULE_DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}")

install(TARGETS h5fortran ${h5fortran_components}
  EXPORT h5fortranTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(DIRECTORY "${H5FORTRAN_MODULE_DIRECTORY}/"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/h5fortran"
  FILES_MATCHING PATTERN "*.mod")

install(EXPORT h5fortranTargets
  FILE h5fortranTargets.cmake
  NAMESPACE h5fortran::
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/h5fortran")
