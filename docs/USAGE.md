# h5fortran の使い方

## 共通の前準備

HDF5 の初期化・終了と、ファイルの open/close は HDF5 ライブラリの関数を直接呼びます。
h5fortran の関数はファイル ID (`file_id`) を受け取るだけです。

```fortran
use hdf5
use h5fort

integer :: hdferr
integer(hid_t) :: file_id

call h5open_f(hdferr)                                          ! HDF5 初期化

call h5fcreate_f("out.h5", H5F_ACC_TRUNC_F, file_id, hdferr)  ! 新規作成
! ... 書き込み処理 ...
call h5fclose_f(file_id, hdferr)

call h5fopen_f("out.h5", H5F_ACC_RDONLY_F, file_id, hdferr)   ! 読み込み
! ... 読み込み処理 ...
call h5fclose_f(file_id, hdferr)

call h5close_f(hdferr)                                         ! HDF5 終了
```

---

## Serial HDF5

### 書き込み

```fortran
! var はスカラー〜4次元配列、型は real64/real32/integer(int32)/logical/character
call h5fort_swrite(file_id, "/dataset_path", var, hdferr)
```

### 読み込み（アロケータブル配列）

```fortran
real(real64), allocatable :: var(:, :)
call h5fort_sread(file_id, "/dataset_path", var, hdferr)
! var は自動的にアロケートされる
```

### 読み込み（固定サイズ配列）

```fortran
real(real64) :: var(100, 3)
call h5fort_sread_fixed(file_id, "/dataset_path", var, hdferr)
```

### オブジェクト指向インターフェース

```fortran
type(t_h5fort_serial) :: h5s
call h5s%write(file_id, "/dataset_path", var, hdferr)
call h5s%read(file_id, "/dataset_path", var, hdferr)
call h5s%read_fixed(file_id, "/dataset_path", var, hdferr)
```

---

## Parallel HDF5

MPI で並列に I/O を行います。各ランクがローカルの配列を持ち、h5fortran が集約して HDF5 に保存します。

### ファイル open 時の並列設定

```fortran
use hdf5
use mpi
use h5fort

integer :: hdferr, ierr
integer(hid_t) :: file_id, fapl_id

call MPI_Init(ierr)
call h5open_f(hdferr)

call h5pcreate_f(H5P_FILE_ACCESS_F, fapl_id, hdferr)
call h5pset_fapl_mpio_f(fapl_id, MPI_COMM_WORLD, MPI_INFO_NULL, hdferr)
call h5fcreate_f("parallel.h5", H5F_ACC_TRUNC_F, file_id, hdferr, access_prp=fapl_id)
call h5pclose_f(fapl_id, hdferr)
```

### 書き込み・読み込み

```fortran
type(t_h5fort_parallel) :: h5fp

! 書き込み（各ランクが異なるサイズの配列を書ける）
call h5fp%write(file_id, "/data", local_array, hdferr)

! 読み込み（アロケータブル）
call h5fp%read(file_id, "/data", local_array_read, hdferr)

! 読み込み（固定サイズ）
call h5fp%read_fixed(file_id, "/data", local_array_fixed, hdferr)
```

### HDF5 内部のデータ構造

並列データは以下の構造で保存されます（`/data` の場合）:

```
/data/__data__    [total_count]        全ランク分のデータ
/data/__count__   [nprocs]             各ランクの要素数
/data/__offset__  [nprocs]             各ランクの先頭オフセット
```

データセット名 `__count__` / `__offset__` はコンパイル時マクロで変更できます:

```fortran
! h5fort_config.inc または前処理オプションで指定
#define H5FORT_DSET_COUNT_DNAME  "count"
#define H5FORT_DSET_OFFSET_DNAME "offset"
```
