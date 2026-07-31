set(_h5fortran_version_file
    "${CMAKE_CURRENT_LIST_DIR}/../postprocess/src/h5xdmf/_version.py")
file(
  STRINGS "${_h5fortran_version_file}" _h5fortran_version_line
  REGEX "^__version__ = \"[0-9]+\\.[0-9]+\\.[0-9]+\"$"
  LIMIT_COUNT 1)
string(
  REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+"
  H5FORTRAN_VERSION "${_h5fortran_version_line}")

if(NOT H5FORTRAN_VERSION)
  message(FATAL_ERROR "Could not read the h5fortran version from ${_h5fortran_version_file}")
endif()

unset(_h5fortran_version_file)
unset(_h5fortran_version_line)
