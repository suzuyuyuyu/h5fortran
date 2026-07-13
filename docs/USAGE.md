# h5fortran の使い方

## Serial: OOP API

通常は `t_h5fort_serial` を使うと、HDF5 の file ID と直前のエラーがオブジェクト内にまとまります。

```fortran
use h5fort
use iso_fortran_env, only: real64

type(t_h5fort_serial) :: file
real(real64) :: values(3) = [1, 2, 3]
real(real64), allocatable :: restored(:)

file%f_name = "result.h5"
call file%open(H5FORTRAN_FORCE_WRITE)
call file%write("/result/value", values, units="m/s")
if (file%hdferr /= 0) error stop "write failed"
call file%close()

call file%open(H5FORTRAN_READ_ONLY)
call file%read("/result/value", restored)
if (file%hdferr /= 0) error stop "read failed"
call file%close()
```

`open()` の mode は次のとおりです。

- `H5FORTRAN_FORCE_WRITE`: 新規作成し、既存ファイルを切り詰める
- `H5FORTRAN_READ_ONLY`: 読み込み専用で開く
- 省略: 読み書き可能で既存ファイルを開く

`write` は中間 group を自動作成します。既存 dataset を置き換える場合は `mode=H5FORTRAN_FORCE_WRITE` を渡します。`attrs` には `t_hdf5_attr` の配列、`units` には文字列を指定できます。

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
```

## Parallel: OOP API

MPI 初期化後、全 rank が同じ順序で `open` / `write` / `read` / `close` を呼びます。配列の最終次元が rank 間で分割され、それ以外の次元は全 rank で一致している必要があります。

```fortran
use h5fort
use mpi
use iso_fortran_env, only: real64

type(t_h5fort_parallel) :: file
real(real64) :: local_values(10)
real(real64), allocatable :: restored(:)

call MPI_Init(ierr)
file%f_name = "parallel.h5"
call file%open(H5FORTRAN_FORCE_WRITE)
call file%write("/value", local_values)
call file%close()

call file%open(H5FORTRAN_READ_ONLY)
call file%read("/value", restored)
call file%close()
call MPI_Finalize(ierr)
```

手続き API は `h5fort_pwrite`、`h5fort_pread`、`h5fort_pread_fixed` です。Parallel の文字列 I/O は現在未実装です。

## Parallel の保存形式

例えば `/value` は次のように保存されます。

```text
/value/data       全 rank のデータ
/value/__count__  rank ごとの分割要素数
/value/__offset__ rank ごとの開始位置
```

詳細な型・rank とエラー契約は [SPEC.md](SPEC.md) を参照してください。
