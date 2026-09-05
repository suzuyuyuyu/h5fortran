cmake_minimum_required(VERSION 3.20)
project(
    h5fortran
    VERSION 1.1.0
    DESCRIPTION "Fortran interface to HDF5"
    LANGUAGES C Fortran
)

file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/generated")
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/src/h5fort_version.F90.in"
  "${CMAKE_CURRENT_BINARY_DIR}/generated/h5fort_version.F90"
  @ONLY)

include(CTest)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

option(H5FORTRAN_ENABLE_PARALLEL "Build the parallel MPI API" OFF)
option(H5FORTRAN_BUILD_EXAMPLES "Build the example programs" ON)
option(H5FORTRAN_BUILD_TESTS "Build the test programs" ${BUILD_TESTING})

set(CMAKE_Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/mod")
file(MAKE_DIRECTORY "${CMAKE_Fortran_MODULE_DIRECTORY}")

set(H5FORTRAN_HDF5_ROOT "" CACHE PATH "HDF5 installation prefix")
if(H5FORTRAN_HDF5_ROOT)
  set(HDF5_ROOT "${H5FORTRAN_HDF5_ROOT}")
  unset(HDF5_DIR CACHE)
endif()
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

configure_package_config_file(
  "${PROJECT_SOURCE_DIR}/cmake/h5fortranConfig.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/h5fortranConfig.cmake"
  INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/h5fortran")
write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/h5fortranConfigVersion.cmake"
  COMPATIBILITY SameMajorVersion)
install(FILES
  "${CMAKE_CURRENT_BINARY_DIR}/h5fortranConfig.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/h5fortranConfigVersion.cmake"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/h5fortran")

if(H5FORTRAN_BUILD_TESTS)
  add_subdirectory(test)
endif()
