# How to Use h5fortran

## Serial HDF5

logical variables are stored as 0 (false) and 1 (true) in HDF5 files. When reading logical variables, the values will be converted to .false. and .true. in Fortran.
```fortran
! `var` can be a scalar or array from 1 to 4 dimensions, and integer, real, character, or logical
call h5fort_read(h5file_id, dataset_name, var, hdferr)

! `array` must be a non-allocatable array of 1 to 4 dimensions, and integer, real, character, or logical
call h5fort_read_fixed(h5file_id, dataset_name, array, hdferr)

! `var` can be a scalar or array from 1 to 4 dimensions, and integer, real, character, or logical
call h5fort_write(h5file_id, dataset_name, var, hdferr)

! object-style wrapper around h5fort_write
type(t_h5fort_serial) :: h5fort_serial
call h5fort_serial%write(h5file_id, dataset_name, var, hdferr)

```


## Parallel HDF5

### Parallel HDF5 for general I/O
Variables `var` (either scalar or array) can be read/written in the following way:
```fortran
call h5fort_p%read(h5file_id, dataset_name, var, hdferr)
call h5fort_p%write(h5file_id, dataset_name, var, hdferr)

```

HDF5 stores the var over multiple processes in a contiguous manner.
```
/partition/particles/point_coord/data    [num_particles, 3]
/partition/particles/point_coord/count   [nprocs]
/partition/particles/point_coord/offset  [nprocs]

```
Where `num_particles` is the MPI-wide total number of particles, and `nprocs` is the number of MPI processes.
Note that the `count` and `offset` are used to determine the local portion of the data when reading in parallel.


### Parallel HDF5 for HDF5/XDMF visualization outupt

```fortran


```
