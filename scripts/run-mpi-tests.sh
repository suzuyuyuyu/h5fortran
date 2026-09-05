#!/bin/bash

#========== Slurm Option ==========
#SBATCH -p gr10353b
#SBATCH -t 00:30:00
#SBATCH -J h5fort-mpi
#SBATCH --rsc p=4:t=1:c=1
#SBATCH -o stdout/%x.%j
#SBATCH -e stderr/%x.%j

#========= Shell Script ==========
#
# Runs the MPI-labelled tests. They must NOT be launched on a login node, at
# any rank count:
#
#   login node:   ctest --test-dir <build> -L quick    # serial only
#   batch:        sbatch scripts/run-mpi-tests.sh      # this script
#
# Unlike the h5c and h5cpp scripts, this one drives ctest rather than srun'ing
# the binaries itself. Each test here declares its own rank count in
# test/CMakeLists.txt -- `parallel` wants 4 and `visualization_hdf5` wants 2 --
# so letting ctest launch them keeps that knowledge in one place. The
# allocation above must therefore be at least as large as the largest test.
#
# I_MPI_HYDRA_BOOTSTRAP makes Intel MPI's mpiexec launch through Slurm instead
# of ssh, which is what makes running it inside a job work at all.
#
# The build must already be configured with H5FORTRAN_ENABLE_PARALLEL=ON.
# Note that its default is OFF, and the intel-mpi-laurel preset does not set
# it, so it has to be passed explicitly:
#
#   cmake --preset intel-mpi-laurel -DH5FORTRAN_ENABLE_PARALLEL=ON
#   cmake --build --preset intel-mpi-laurel
#
# NOTE: stdout/ and stderr/ must exist BEFORE submission. Slurm opens the files
# named by -o/-e before this script runs, so creating them here would be too
# late and the job would fail in under a second with no output at all.

set -euo pipefail
set -x

cd "${SLURM_SUBMIT_DIR:?SLURM_SUBMIT_DIR is not set}"

# Tolerate submission from either the repository root or scripts/.
if [[ ! -f CMakeLists.txt && -f ../CMakeLists.txt ]]; then
    cd ..
fi
H5FORT_ROOT="$(pwd)"

# Slurm opens the -o/-e files above before this script runs, so stdout/ and
# stderr/ must already exist at submission time -- a .gitkeep in each keeps
# them in the repository. This mkdir only covers someone deleting them later.
mkdir -p stdout stderr

ln -sf "./stdout/${SLURM_JOB_NAME}.${SLURM_JOB_ID}" ./out
ln -sf "./stderr/${SLURM_JOB_NAME}.${SLURM_JOB_ID}" ./err

# if $SHELL is not bash and loading modules is necessary, uncomment
. /usr/share/Modules/init/bash
export LD_LIBRARY_PATH=${HOME}/.local/opt/intel/phdf5/lib:${LD_LIBRARY_PATH:-}
export OMP_NUM_THREADS=1
export I_MPI_HYDRA_BOOTSTRAP=slurm

BUILD_DIR="${BUILD_DIR:-${H5FORT_ROOT}/_build}"
CTEST_LABEL="${CTEST_LABEL:-mpi}"

# Resolve to an absolute path: a BUILD_DIR passed in relative would stop
# resolving if anything below changed directory.
if [[ "${BUILD_DIR}" != /* ]]; then
    BUILD_DIR="${H5FORT_ROOT}/${BUILD_DIR}"
fi

if [[ ! -f "${BUILD_DIR}/CMakeCache.txt" ]]; then
    set +x
    echo "error: ${BUILD_DIR} is not configured." >&2
    echo "Configure it first, on the login node:" >&2
    echo "  cmake --preset intel-mpi-laurel -DH5FORTRAN_ENABLE_PARALLEL=ON" >&2
    exit 1
fi

if ! grep -q '^H5FORTRAN_ENABLE_PARALLEL:BOOL=ON' "${BUILD_DIR}/CMakeCache.txt"; then
    set +x
    echo "error: ${BUILD_DIR} was configured without H5FORTRAN_ENABLE_PARALLEL=ON," >&2
    echo "so no mpi-labelled test exists in it. Reconfigure with that option." >&2
    exit 1
fi

cmake --build "${BUILD_DIR}" -j "${SLURM_CPUS_PER_TASK:-4}"

ctest --test-dir "${BUILD_DIR}" -L "${CTEST_LABEL}" --output-on-failure
