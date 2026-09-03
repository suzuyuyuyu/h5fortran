#!/bin/bash
#SBATCH -p gr10353b
#SBATCH -t 00:10:00
#SBATCH -J h5fortran-test
#SBATCH --rsc p=4:t=1:c=1
#SBATCH -o log/%x.%j.out
#SBATCH -e log/%x.%j.err

set -euo pipefail

cd "${SLURM_SUBMIT_DIR:?SLURM_SUBMIT_DIR is not set}"
if [[ ! -f CMakeLists.txt && -f ../CMakeLists.txt ]]; then
  cd ..
fi
repo_dir=$(pwd)
build_dir="${BUILD_DIR:-${repo_dir}/build/intel-mpi}"

cd "${build_dir}/test"
srun -n 4 ./test_parallel
srun -n 2 ./test_visualization
