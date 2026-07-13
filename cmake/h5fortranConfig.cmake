include(CMakeFindDependencyMacro)
find_dependency(HDF5 REQUIRED COMPONENTS Fortran HL)
include("${CMAKE_CURRENT_LIST_DIR}/h5fortranTargets.cmake")
