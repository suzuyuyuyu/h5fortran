add_executable(test_serial test-serial.F90)
target_link_libraries(test_serial PRIVATE h5fortran)
target_include_directories(test_serial PRIVATE "${H5FORTRAN_MODULE_DIRECTORY}")
set_target_properties(test_serial PROPERTIES
  Fortran_PREPROCESS ON
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod")

configure_file(input-serial.dat input-serial.dat COPYONLY)
add_test(NAME serial COMMAND test_serial)
set_tests_properties(serial PROPERTIES
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

add_executable(test_parallel test-parallel.F90)
target_link_libraries(test_parallel PRIVATE h5fortran)
target_include_directories(test_parallel PRIVATE "${H5FORTRAN_MODULE_DIRECTORY}")
set_target_properties(test_parallel PROPERTIES
  Fortran_PREPROCESS ON
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod")

find_program(H5FORTRAN_MPIEXEC
  NAMES mpiexec mpirun
  PATHS
    "/opt/system/app/intel/2025.0.1/mpi/2021.14/bin"
    "/opt/system/app/intel/2023.2/mpi/2021.10/bin"
  PATH_SUFFIXES bin)

if(H5FORTRAN_MPIEXEC)
  add_test(NAME parallel
    COMMAND "${H5FORTRAN_MPIEXEC}" -n 4 $<TARGET_FILE:test_parallel>)
  configure_file(input-parallel.dat input-parallel.dat COPYONLY)
  set_tests_properties(parallel PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
else()
  message(WARNING "mpiexec/mpirun was not found; parallel CTest entry was not added")
endif()
