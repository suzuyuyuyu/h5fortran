# h5fortran の使い方

## 製品・HDF5 scheme version

`use h5fort`により、製品と現在のHDF5出力schemeを参照できる。

```fortran
print *, H5FORTRAN_VERSION
print *, H5FORTRAN_VERSION_MAJOR
print *, H5FORTRAN_SCHEME_VERSION
```

`H5FORTRAN_SCHEME_VERSION`は製品majorと一致する。HDF5 readerはファイルrootの
`scheme_version`属性を読み、対応するschemeを選ぶ。

## Serial: OOP API

通常は `t_h5fort_serial` を使うと、HDF5 の file ID と直前のエラーがオブジェクト内にまとまります。

```fortran
use hdf5, only: h5open_f, h5close_f
use h5fort
use iso_fortran_env, only: real64

type(t_h5fort_serial) :: file
integer :: hdferr
real(real64) :: values(3) = [1, 2, 3]
real(real64), allocatable :: restored(:)

call h5open_f(hdferr)
if (hdferr /= 0) error stop "HDF5 initialization failed"

file%f_name = "result.h5"
call file%open(H5FORTRAN_FORCE_WRITE)
call file%write("/result/value", values, units="m/s")
if (file%hdferr /= 0) error stop "write failed"
call file%close()

call file%open(H5FORTRAN_READ_ONLY)
call file%read("/result/value", restored)
if (file%hdferr /= 0) error stop "read failed"
call file%close()

call h5close_f(hdferr)
if (hdferr /= 0) error stop "HDF5 finalization failed"
```

`h5fortran` はHDF5ライブラリの開始・終了を行いません。利用者が処理全体で
`h5open_f` と `h5close_f` をそれぞれ1回呼びます。`h5close_f` はすべての
`t_h5fort_serial` ファイルを閉じた後に呼んでください。

`open()` の mode は次のとおりです。

- `H5FORTRAN_FORCE_WRITE`: 新規作成し、既存ファイルを切り詰める
- `H5FORTRAN_READ_ONLY`: 読み込み専用で開く
- 省略: 読み書き可能で既存ファイルを開く

`write` は中間 group を自動作成します。既存 dataset を置き換える場合は `mode=H5FORTRAN_FORCE_WRITE` を渡します。`attrs` には `t_hdf5_attr` の配列、`units` には文字列を指定できます。

文字列 attribute は dataset の書き込みとは独立して読み書きできます。対象 path には dataset、group、root group を指定できます。

```fortran
character(len=:), allocatable :: description

call file%write_attribute("/result/value", "description", "flow velocity")
call file%read_attribute("/result/value", "description", description)
```

固定サイズ配列へ読むときは `read_fixed` を使います。dataset と shape が違う場合は `hdferr` が非ゼロになります。logical 配列も利用できます。

```fortran
logical :: flags(2, 3)
call file%read_fixed("/flags", flags)
```

## Serial: 手続き API

既存コードが HDF5 file ID を管理している場合は、低水準 API を直接呼べます。

```fortran
call h5fort_swrite(file_id, "/value", values, hdferr)
call h5fort_sread(file_id, "/value", restored, hdferr)
call h5fort_sread_fixed(file_id, "/flags", flags, hdferr)
call h5fort_write_attribute(file_id, "/value", "units", "m/s", hdferr)
call h5fort_read_attribute(file_id, "/value", "units", units, hdferr)
```

## Parallel: OOP API

MPI 初期化後、全 rank が同じ順序で `open` / `write` / `read` / `close` を呼びます。配列の最終次元が rank 間で分割され、それ以外の次元は全 rank で一致している必要があります。

```fortran
use hdf5, only: h5open_f, h5close_f
use h5fort
use mpi
use iso_fortran_env, only: real64

type(t_h5fort_parallel) :: file
integer :: ierr, hdferr
real(real64) :: local_values(10)
real(real64), allocatable :: restored(:)

call MPI_Init(ierr)
call h5open_f(hdferr)
if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)

file%f_name = "parallel.h5"
call file%open(H5FORTRAN_FORCE_WRITE)
call file%write("/value", local_values)
call file%close()

call file%open(H5FORTRAN_READ_ONLY)
call file%read("/value", restored)
call file%close()

call h5close_f(hdferr)
if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
call MPI_Finalize(ierr)
```

Parallelでは全rankが `MPI_Init` の後に `h5open_f`、全HDF5ファイルを閉じた後かつ
`MPI_Finalize` の前に `h5close_f` を呼びます。ファイルごとの `open` / `close` と
HDF5ライブラリ全体の `h5open_f` / `h5close_f` は別のライフサイクルです。

手続き API は `h5fort_pwrite`、`h5fort_pread`、`h5fort_pread_fixed` です。Parallel の文字列 I/O は現在未実装です。

## Parallel の保存形式

例えば `/value` は次のように保存されます。

```text
/value/data       全 rank のデータ
/value/__partition__  rank境界（長さはMPI process数 + 1）
```

例えば各rankの要素数が `[2, 3, 0, 4]` なら、`__partition__` は
`[0, 2, 5, 5, 9]` です。rank `r` の開始位置は `partition(r)`、要素数は
`partition(r+1) - partition(r)` です。

詳細な型・rank とエラー契約は [SPEC.md](SPEC.md) を参照してください。

可視化用のParallel HDF5 writerとPythonポストプロセスは
[USAGE-visualization.md](USAGE-visualization.md)、
出力ファイルとmanifestの責務は [POSTPROCESS.md](POSTPROCESS.md) を参照してください。
