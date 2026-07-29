#!/bin/sh
set -eu

example_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "${example_dir}/../.." && pwd)
build_dir=${1:-"${repo_dir}/build"}
mpiexec_bin=${MPIEXEC:-mpiexec}
num_ranks=${NPROCS:-2}

case "${build_dir}" in
  /*) ;;
  *) build_dir="${repo_dir}/${build_dir}" ;;
esac

cmake --build "${build_dir}" --target example_visualization

(
  cd "${example_dir}"
  "${mpiexec_bin}" -n "${num_ranks}" "${build_dir}/test/example_visualization"
)

(
  cd "${repo_dir}/postprocess"
  uv run h5xdmf "${example_dir}/result/seq*.h5" \
    --metadata "${example_dir}/result/metadata.h5" \
    --outdir "${example_dir}/result" \
    --rebuild
)

echo "Generated visualization example in ${example_dir}/result"
