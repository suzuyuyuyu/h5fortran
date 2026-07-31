cmake_minimum_required(VERSION 3.20)
include(cmake/h5fortranVersion.cmake)
project(
    h5fortran
    VERSION "${H5FORTRAN_VERSION}"
    DESCRIPTION "Fortran interface to HDF5"
    LANGUAGES Fortran
)

file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/generated")
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/src/h5fort_version.F90.in"
  "${CMAKE_CURRENT_BINARY_DIR}/generated/h5fort_version.F90"
  @ONLY)

include(CTest)
include(GNUInstallDirs)

option(H5FORTRAN_ENABLE_SERIAL "Build the serial API" ON)
option(H5FORTRAN_ENABLE_PARALLEL "Build the parallel MPI API" ON)
option(H5FORTRAN_BUILD_EXAMPLES "Build the example programs" ON)

if(NOT H5FORTRAN_ENABLE_SERIAL AND NOT H5FORTRAN_ENABLE_PARALLEL)
  message(FATAL_ERROR "At least one of H5FORTRAN_ENABLE_SERIAL or H5FORTRAN_ENABLE_PARALLEL must be ON")
endif()

set(CMAKE_Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/mod")
file(MAKE_DIRECTORY "${CMAKE_Fortran_MODULE_DIRECTORY}")

if(H5FORTRAN_ENABLE_PARALLEL)
  set(HDF5_PREFER_PARALLEL ON)
endif()
find_package(HDF5 REQUIRED COMPONENTS Fortran HL)

if(H5FORTRAN_ENABLE_PARALLEL)
  find_package(MPI REQUIRED COMPONENTS Fortran)
  if(DEFINED HDF5_IS_PARALLEL AND NOT HDF5_IS_PARALLEL)
    message(FATAL_ERROR "The parallel API requires an HDF5 build with parallel I/O support")
  endif()
endif()

add_library(h5fortran_hdf5 INTERFACE)
target_link_libraries(
    h5fortran_hdf5
    INTERFACE
    hdf5::hdf5_fortran
    hdf5::hdf5_hl_fortran
)

add_subdirectory(src)

if(H5FORTRAN_BUILD_EXAMPLES)
  add_subdirectory(example)
endif()

configure_file(
  "${PROJECT_SOURCE_DIR}/cmake/h5fortranConfig.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/h5fortranConfig.cmake"
  @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/h5fortranConfig.cmake"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/h5fortran")

if(BUILD_TESTING)
  add_subdirectory(test)
endif()
