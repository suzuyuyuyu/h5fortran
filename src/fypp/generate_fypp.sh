#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src_dir=$(CDPATH= cd -- "${script_dir}/.." && pwd)
fypp_bin=${FYPP:-fypp}
check=false

if [ "${1:-}" = "--check" ]; then
  check=true
elif [ "$#" -ne 0 ]; then
  echo "usage: $0 [--check]" >&2
  exit 2
fi

if ! command -v "${fypp_bin}" >/dev/null 2>&1; then
  echo "error: fypp was not found (install fypp 3.2 or set FYPP)" >&2
  exit 127
fi

generate() {
  input=$1
  output=$2
  destination="${src_dir}/${output}"
  if [ "${check}" = true ]; then
    generated="${tmp_dir}/${output}"
    mkdir -p "$(dirname -- "${generated}")"
    destination=${generated}
  fi
  "${fypp_bin}" -I "${script_dir}/common" \
    "${script_dir}/${input}" "${destination}"
  if [ "${check}" = true ] && ! cmp -s "${destination}" "${src_dir}/${output}"; then
    echo "error: ${output} is out of date; run src/fypp/generate_fypp.sh" >&2
    exit 1
  fi
}

if [ "${check}" = true ]; then
  tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/h5fortran-fypp.XXXXXX")
  trap 'rm -rf "${tmp_dir}"' EXIT HUP INT TERM
fi

generate serial/h5fort_serial.fypp serial/h5fort_serial.F90
generate serial/h5fort_serial_attribute.fypp serial/h5fort_serial_attribute.F90
generate serial/h5fort_serial_read.fypp serial/h5fort_serial_read.F90
generate serial/h5fort_serial_read_fixed.fypp serial/h5fort_serial_read_fixed.F90
generate serial/h5fort_serial_write.fypp serial/h5fort_serial_write.F90
generate parallel/h5fort_parallel.fypp parallel/h5fort_parallel.F90
generate parallel/h5fort_parallel_read.fypp parallel/h5fort_parallel_read.F90
generate parallel/h5fort_parallel_read_fixed.fypp parallel/h5fort_parallel_read_fixed.F90
generate parallel/h5fort_parallel_write.fypp parallel/h5fort_parallel_write.F90
generate parallel/h5fort_parallel_visualization.fypp parallel/h5fort_parallel_visualization.F90

if [ "${check}" = true ]; then
  echo "Generated Fortran sources are up to date ($("${fypp_bin}" --version))."
else
  echo "Generated serial and parallel Fortran sources with $("${fypp_bin}" --version)."
fi
