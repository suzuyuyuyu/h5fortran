cmake_minimum_required(VERSION 3.20)
project(h5fortran LANGUAGES Fortran)

include(CTest)

set(CMAKE_Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/mod")
file(MAKE_DIRECTORY "${CMAKE_Fortran_MODULE_DIRECTORY}")

set(H5FORTRAN_PHDF5_ROOT "$ENV{HOME}/.local/opt/intel/phdf5" CACHE PATH
  "Parallel HDF5 installation prefix")

set(HDF5_ROOT "${H5FORTRAN_PHDF5_ROOT}")
set(HDF5_PREFER_PARALLEL ON)
find_package(HDF5 REQUIRED COMPONENTS Fortran HL)

file(STRINGS "${H5FORTRAN_PHDF5_ROOT}/include/H5pubconf.h" _h5_parallel
  REGEX "^#define H5_HAVE_PARALLEL 1")
if(NOT _h5_parallel)
  message(FATAL_ERROR "HDF5 at ${H5FORTRAN_PHDF5_ROOT} is not parallel (H5_HAVE_PARALLEL not set)")
endif()
message(STATUS "HDF5 parallel: yes (${H5FORTRAN_PHDF5_ROOT})")

add_library(h5fortran_hdf5 INTERFACE)
target_include_directories(h5fortran_hdf5 INTERFACE ${HDF5_INCLUDE_DIRS})
target_link_libraries(h5fortran_hdf5 INTERFACE
  ${HDF5_Fortran_HL_LIBRARIES}
  ${HDF5_Fortran_LIBRARIES}
  ${HDF5_LIBRARIES})
target_link_options(h5fortran_hdf5 INTERFACE
  "-Wl,-rpath,${H5FORTRAN_PHDF5_ROOT}/lib")

add_subdirectory(src)

if(BUILD_TESTING)
  add_subdirectory(test)
endif()
