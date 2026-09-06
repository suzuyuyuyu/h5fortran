# 2026-09-06: Writer decisions and log preservation

This append-only session record uses commit messages and code inspection.
No builds, tests, or distributed jobs were run during this documentation work.
Historical test results are attributed below rather than claimed as reruns.

## Why the first split was insufficient

14e8f1c describes the previous single-target writer with compile-time MPI
seams. The owner identifies this as the first split attempt: an MPI build
could only write collectively, so compile-time selection did not meet the
need to use both modes in one build. Keeping the whole writer in the serial
base and extending it for parallel operations avoided duplicating the layout.
The commit reports shrinking the parallel module from 2350 lines to 60.

H5FORTRAN_ENABLE_SERIAL was removed rather than preserved as a choice because
the parallel library already depended on serial objects. The switch only hid
an API that was being built anyway; retaining it would preserve a misleading
configuration distinction (14e8f1c).

## Rejected two-installation CMake attempt

The owner reports an abandoned approach requiring a second, serial HDF5
installation in every parallel build: serial objects were compiled against
that installation's Fortran modules, then linked to parallel HDF5 through
INTERFACE_LINK_LIBRARIES_DIRECT. It was rejected because mixing module files
and libraries from different HDF5 builds risks an ABI mismatch. Linking and
appearing to work would be particularly dangerous evidence, not validation.
The replacement rule was one HDF5 per build.

A history search for INTERFACE_LINK_LIBRARIES_DIRECT found no committed
occurrence, so the abandoned attempt is recorded as the owner's account,
not a recovered commit. Current CMake selects one HDF5 package with Fortran
and HL components and checks parallel support when requested; this supports
the final rule but cannot independently prove the intermediate experiment.

## What was measured, and what that establishes

14e8f1c reports serial quick 4/4, parallel quick 4/4, and four parallel checks
at four ranks, including both writers' structural agreement. It describes
parallel output as "byte-identical" to the pre-split implementation over five
steps at four ranks and points to scripts/compare-viz-baseline.sh.

We read that script without executing it. It compares corresponding HDF5
files using h5diff, not a raw binary comparator. Thus the committed report
records the claimed byte identity, but the reproducible check visible here
establishes HDF5 content equality; literal file-byte identity is not
independently demonstrated by that script. No new performance measurement
or baseline comparison was made during cleanup.

## Why an in-script directory creation could not work

b8bff5b reports fresh-clone jobs dying in under a second without output.
The scheduler opens stdout/stderr redirection files before starting the job
script. An in-script mkdir was therefore too late. Ignoring the directories
outright meant the clone contained no output destination. Tracking .gitkeep
files while ignoring generated contents was chosen so directories existed
before submission. The reported failure timing comes from the commit, not a
new submission. This also explains the output-directory prerequisite retained
in h5c's usage instructions.

## Cleanup attempt and owner's correction

CHANGELOG stayed at 27 lines. We normalized the version prefix and shortened
the Tensor6 explanation because SPEC already documented the consumer's order.
9db9a35 records that the earlier text followed the XDMF3 order, then the
unchanged-column path through h5xdmf made the consumer convention decisive.
This was documentation reasoning, not a ParaView measurement in this session;
we found no such measurement in that commit.

The first cleanup renamed and translated log/v1.md into a dated English file.
The owner rejected rewriting historical records. We restored log/v1.md
byte-for-byte from HEAD, removed only our newly created translated replacement,
and repaired its changelog link. Its Japanese text and non-dated name remain
as historical evidence under the explicit preservation instruction. They are
not a template for new logs. Its old product/scheme coupling describes that
moment rather than the current version policy.

The two specified untracked job-output files,
h5fortran-test.23445757.err and h5fortran-test.23445757.out, were deleted after
checking they were not tracked. No other historical log was discarded.
