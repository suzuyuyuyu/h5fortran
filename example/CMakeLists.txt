cmake_minimum_required(VERSION 3.20)
project(h5fortran_examples LANGUAGES Fortran)

# Allow both:
#   cmake -S .       -B build          (included by the main project)
#   cmake -S example -B example/_build (standalone examples)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(BUILD_TESTING OFF CACHE BOOL "Disable library tests in an example-only build" FORCE)
  set(H5FORTRAN_BUILD_EXAMPLES OFF CACHE BOOL "Avoid adding examples recursively" FORCE)
  add_subdirectory(".." "${CMAKE_CURRENT_BINARY_DIR}/h5fortran")
endif()

set(h5fortran_example_targets)

function(h5fortran_add_example target source)
  add_executable("${target}" "${source}")
  target_link_libraries("${target}" PRIVATE h5fortran)
  set_target_properties("${target}" PROPERTIES
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod-${target}"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/example")
  list(APPEND h5fortran_example_targets "${target}")
  set(h5fortran_example_targets "${h5fortran_example_targets}" PARENT_SCOPE)
endfunction()

if(H5FORTRAN_ENABLE_SERIAL)
  h5fortran_add_example(example_serial serial/main.F90)
  h5fortran_add_example(example_serial_oop serial-oop/main.F90)
endif()

if(H5FORTRAN_ENABLE_PARALLEL)
  h5fortran_add_example(example_parallel parallel/main.F90)
  h5fortran_add_example(example_parallel_oop parallel-oop/main.F90)
  h5fortran_add_example(example_visualization visualization/main.F90)
endif()

add_custom_target(examples DEPENDS ${h5fortran_example_targets})
