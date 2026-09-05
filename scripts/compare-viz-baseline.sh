#!/bin/bash
#
# Runs the visualization example at 4 ranks from two builds and compares the
# HDF5 they produce. Used to prove that a refactor of the parallel writer did
# not change a single byte of its output.
#
#   sbatch scripts/compare-viz-baseline.sh
#
# BASE_DIR and NEW_DIR are build trees configured with H5FORTRAN_BUILD_EXAMPLES=ON.

#========== Slurm Option ==========
#SBATCH -p gr10353b
#SBATCH -t 00:20:00
#SBATCH -J h5fort-vizcmp
#SBATCH --rsc p=4:t=1:c=1
#SBATCH -o stdout/%x.%j
#SBATCH -e stderr/%x.%j

set -euo pipefail

cd "${SLURM_SUBMIT_DIR:?}"
mkdir -p stdout stderr

. /usr/share/Modules/init/bash
export LD_LIBRARY_PATH=${HOME}/.local/opt/intel/phdf5/lib:${LD_LIBRARY_PATH:-}
export OMP_NUM_THREADS=1
export I_MPI_HYDRA_BOOTSTRAP=slurm

BASE_DIR="${BASE_DIR:-${HOME}/tmp/h5f-baseline/_build}"
NEW_DIR="${NEW_DIR:-$(pwd)/_build}"
WORK="${WORK:-${HOME}/tmp/h5f-vizcmp}"

rm -rf "${WORK}"
mkdir -p "${WORK}/base" "${WORK}/new"

(cd "${WORK}/base" && srun -n "${SLURM_NTASKS}" "${BASE_DIR}/example/example_visualization")
(cd "${WORK}/new"  && srun -n "${SLURM_NTASKS}" "${NEW_DIR}/example/example_visualization")

failed=0
for f in "${WORK}"/base/result/*.h5; do
    name=$(basename "${f}")
    if h5diff -v1 "${f}" "${WORK}/new/result/${name}" >"${WORK}/diff-${name}.txt" 2>&1; then
        echo "identical  ${name}"
    else
        echo "DIFFERENT  ${name}"
        head -40 "${WORK}/diff-${name}.txt"
        failed=$((failed + 1))
    fi
done

echo "=== ${failed} file(s) differ (${SLURM_NTASKS} ranks) ==="
exit "${failed}"
