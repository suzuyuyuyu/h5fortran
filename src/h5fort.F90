#include "h5fort_config.inc"
module h5fort

# if defined(H5FORT_PARALLEL)
  use h5fort_parallel
# endif
# if defined(H5FORT_SERIAL)
  use h5fort_serial
# endif
# if !defined(H5FORT_SERIAL) && !defined(H5FORT_PARALLEL)
#   error "Define H5FORT_SERIAL or H5FORT_PARALLEL when building h5fort."
# endif

  implicit none

  private

# if defined(H5FORT_PARALLEL)
  public :: h5fort_pwrite, h5fort_pread, h5fort_pread_fixed
  public :: t_h5fort_parallel
  public :: t_phdf5_writer
# endif

# if defined(H5FORT_SERIAL)
  public :: h5fort_swrite, h5fort_sread, h5fort_sread_fixed, h5fort_swrite_attr
  public :: t_hdf5_attr, t_h5fort_serial
  public :: H5FORTRAN_FORCE_WRITE
# endif

end module h5fort
