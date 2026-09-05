find_program(FYPP_EXECUTABLE fypp)
if(FYPP_EXECUTABLE)
  add_test(NAME generated_sources
    COMMAND "${PROJECT_SOURCE_DIR}/src/fypp/generate_fypp.sh" --check)
  set_tests_properties(generated_sources PROPERTIES
    ENVIRONMENT "FYPP=${FYPP_EXECUTABLE}"
    LABELS quick)
endif()

add_executable(test_serial test-serial.F90)
target_link_libraries(test_serial PRIVATE h5fortran)
set_target_properties(test_serial PROPERTIES
  Fortran_PREPROCESS ON
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-serial")
add_test(NAME serial COMMAND test_serial)
set_tests_properties(serial PROPERTIES
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  LABELS quick)

add_executable(test_visualization_serial test-visualization-serial.F90)
target_link_libraries(test_visualization_serial PRIVATE h5fortran_serial)
set_target_properties(test_visualization_serial PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-visualization-serial")
add_test(NAME visualization_hdf5_serial COMMAND test_visualization_serial)
set_tests_properties(visualization_hdf5_serial PROPERTIES
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  LABELS quick)

configure_file(consumer/CMakeLists.txt consumer/CMakeLists.txt COPYONLY)
configure_file(consumer/main.F90 consumer/main.F90 COPYONLY)
configure_file(test-visualization-serial.F90 consumer/visualization.F90 COPYONLY)
configure_file(install-consumer.cmake.in install-consumer.cmake @ONLY)
add_test(NAME install_consumer
  COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/install-consumer.cmake")
set_tests_properties(install_consumer PROPERTIES LABELS quick)

if(H5FORTRAN_ENABLE_PARALLEL)
  configure_file(input-parallel.dat input-parallel.dat COPYONLY)
  add_executable(test_parallel test-parallel.F90)
  target_link_libraries(test_parallel PRIVATE h5fortran)
  set_target_properties(test_parallel PROPERTIES
    Fortran_PREPROCESS ON
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-parallel")

  if(MPIEXEC_EXECUTABLE)
    add_test(NAME parallel
      COMMAND "${MPIEXEC_EXECUTABLE}" "${MPIEXEC_NUMPROC_FLAG}" 4 $<TARGET_FILE:test_parallel>)
    set_tests_properties(parallel PROPERTIES
      WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
      LABELS mpi)

    add_executable(test_visualization test-visualization.F90)
    target_link_libraries(test_visualization PRIVATE h5fortran)
    set_target_properties(test_visualization PROPERTIES
      Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-visualization")
    add_test(NAME visualization_hdf5
      COMMAND "${MPIEXEC_EXECUTABLE}" "${MPIEXEC_NUMPROC_FLAG}" 2 $<TARGET_FILE:test_visualization>)
    set_tests_properties(visualization_hdf5 PROPERTIES
      WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
      LABELS mpi)

  endif()
endif()

if(H5FORTRAN_ENABLE_PARALLEL AND MPIEXEC_EXECUTABLE)
  find_program(H5DUMP_EXECUTABLE h5dump HINTS "${HDF5_ROOT}/bin" REQUIRED)
  find_program(H5DIFF_EXECUTABLE h5diff HINTS "${HDF5_ROOT}/bin" REQUIRED)
  add_executable(test_visualization_equivalence test-visualization-serial.F90)
  target_link_libraries(test_visualization_equivalence PRIVATE h5fortran_parallel)
  target_compile_definitions(test_visualization_equivalence PRIVATE VISUALIZATION_EQUIVALENCE)
  set_target_properties(test_visualization_equivalence PROPERTIES
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-visualization-equivalence")
  file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/visualization-equivalence")
  add_test(NAME visualization_equivalence_write
    COMMAND "${MPIEXEC_EXECUTABLE}" "${MPIEXEC_NUMPROC_FLAG}" 1 $<TARGET_FILE:test_visualization_equivalence>)
  set_tests_properties(visualization_equivalence_write PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/visualization-equivalence"
    FIXTURES_SETUP visualization_equivalence LABELS mpi)
  file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/compare-visualization.cmake" CONTENT "
foreach(kind serial equivalent)
  set(path test-visualization-\${kind}.h5)
  execute_process(COMMAND \"${H5DUMP_EXECUTABLE}\" -H \${path}
    RESULT_VARIABLE result OUTPUT_VARIABLE header)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR \"h5dump failed: \${path}\")
  endif()
  string(REPLACE \${path} visualization.h5 header_\${kind} \"\${header}\")
endforeach()
if(NOT header_serial STREQUAL header_equivalent)
  message(FATAL_ERROR \"Visualization paths, shapes, dtypes or attribute definitions differ\")
endif()
execute_process(COMMAND \"${H5DIFF_EXECUTABLE}\" test-visualization-serial.h5 test-visualization-equivalent.h5
  RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR \"Visualization data or attribute values differ\")
endif()
")
  add_test(NAME visualization_equivalence
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/compare-visualization.cmake")
  set_tests_properties(visualization_equivalence PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/visualization-equivalence"
    FIXTURES_REQUIRED visualization_equivalence LABELS mpi)
endif()
