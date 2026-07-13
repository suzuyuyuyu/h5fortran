find_program(FYPP_EXECUTABLE fypp)
if(FYPP_EXECUTABLE)
  add_test(NAME generated_sources
    COMMAND "${CMAKE_SOURCE_DIR}/src/fypp/generate_fypp.sh" --check)
  set_tests_properties(generated_sources PROPERTIES
    ENVIRONMENT "FYPP=${FYPP_EXECUTABLE}")
endif()

if(H5FORTRAN_ENABLE_SERIAL)
  add_executable(test_serial test-serial.F90)
  target_link_libraries(test_serial PRIVATE h5fortran)
  set_target_properties(test_serial PROPERTIES
    Fortran_PREPROCESS ON
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-serial")
  add_test(NAME serial COMMAND test_serial)
  set_tests_properties(serial PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

  add_executable(example_serial "${CMAKE_SOURCE_DIR}/example/small-serial.F90")
  target_link_libraries(example_serial PRIVATE h5fortran)
  set_target_properties(example_serial PROPERTIES
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-example-serial")

  configure_file(consumer/CMakeLists.txt consumer/CMakeLists.txt COPYONLY)
  configure_file(consumer/main.F90 consumer/main.F90 COPYONLY)
  configure_file(install-consumer.cmake.in install-consumer.cmake @ONLY)
  add_test(NAME install_consumer
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/install-consumer.cmake")
endif()

if(H5FORTRAN_ENABLE_PARALLEL)
  configure_file(input-parallel.dat input-parallel.dat COPYONLY)
  add_executable(test_parallel test-parallel.F90)
  target_link_libraries(test_parallel PRIVATE h5fortran)
  set_target_properties(test_parallel PROPERTIES
    Fortran_PREPROCESS ON
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-parallel")

  add_executable(example_parallel "${CMAKE_SOURCE_DIR}/example/small-parallel.F90")
  target_link_libraries(example_parallel PRIVATE h5fortran)
  set_target_properties(example_parallel PROPERTIES
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-example-parallel")

  if(MPIEXEC_EXECUTABLE)
    add_test(NAME parallel
      COMMAND "${MPIEXEC_EXECUTABLE}" "${MPIEXEC_NUMPROC_FLAG}" 4 $<TARGET_FILE:test_parallel>)
    set_tests_properties(parallel PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

    add_executable(test_xdmf test-xdmf.F90)
    target_link_libraries(test_xdmf PRIVATE h5fortran)
    set_target_properties(test_xdmf PROPERTIES
      Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-xdmf")
    add_test(NAME xdmf
      COMMAND "${MPIEXEC_EXECUTABLE}" "${MPIEXEC_NUMPROC_FLAG}" 2 $<TARGET_FILE:test_xdmf>)
    set_tests_properties(xdmf PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
  endif()
endif()
