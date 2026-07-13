#include "h5fort_config.inc"
module h5fort

#ifdef H5FORTRAN_PARALLEL
  use h5fort_parallel, H5FORTRAN_FORCE_WRITE_PARALLEL => H5FORTRAN_FORCE_WRITE, &
    H5FORTRAN_READ_ONLY_PARALLEL => H5FORTRAN_READ_ONLY
#endif
#ifdef H5FORTRAN_SERIAL
  use h5fort_serial, H5FORTRAN_FORCE_WRITE_SERIAL => H5FORTRAN_FORCE_WRITE, &
    H5FORTRAN_READ_ONLY_SERIAL => H5FORTRAN_READ_ONLY
#endif
#ifndef H5FORTRAN_SERIAL
#ifndef H5FORTRAN_PARALLEL
#error "Define H5FORTRAN_SERIAL or H5FORTRAN_PARALLEL when building h5fort."
#endif
#endif

  implicit none

  private

  integer, parameter, public :: H5FORTRAN_FORCE_WRITE = 1
  integer, parameter, public :: H5FORTRAN_READ_ONLY = 2

#ifdef H5FORTRAN_PARALLEL
  public :: h5fort_pwrite, h5fort_pread, h5fort_pread_fixed
  public :: t_h5fort_parallel
  public :: t_phdf5_writer
#endif

#ifdef H5FORTRAN_SERIAL
  public :: h5fort_swrite, h5fort_sread, h5fort_sread_fixed, h5fort_swrite_attr
  public :: t_hdf5_attr, t_h5fort_serial
#endif

end module h5fort
