# h5fortran 仕様

## バージョン管理

`h5fortran`と`h5xdmf`は独立してリリースし、それぞれのSemVerを使う。
h5fortranの製品バージョンは`CMakeLists.txt`の`project(VERSION)`を正本とする。

HDF5 root属性の`scheme_version`は両製品のSemVerとは独立したdisk formatの版である。
HDF5内部レイアウトに非互換変更がある場合だけschemeを更新し、readerは対応する旧
schemeを残す。CMakeは`h5fort_version` moduleを生成し、利用者へ次を公開する。

- `H5FORTRAN_VERSION`: 製品の完全なSemVer文字列
- `H5FORTRAN_VERSION_MAJOR`: 製品major
- `H5FORTRAN_SCHEME_VERSION`: 現在書き出す可視化HDF5 scheme

readerは製品バージョンを決め打ちせず、入力HDF5の`scheme_version`を読んで登録済み
scheme実装を選ぶ。これによりmajor更新後も、対応する旧scheme readerを残す限り古い
HDF5を読める。XDMFの`Version="3.0"`は外部規格の版であり、製品バージョンとは
独立している。

## 公開 API

| API | Serial | Parallel |
|---|---:|---:|
| allocatable read / write | scalar, 1D–4D | scalar, 1D–4D |
| fixed-size read | 1D–4D | 1D–4D |
| `real(real64)` | yes | yes |
| `real(real32)` | yes | yes |
| `integer(int32)` | yes | yes |
| `integer(int64)` | yes | yes |
| `logical` | yes | yes |
| scalar `character` | yes | no |
| 文字列属性・`units` | read / write | no |
| 数値属性 (`real32/64`, `int32/64`) | scalar / 1D read / write | no |

公開する手続き generic は Serial の `h5fort_swrite` / `h5fort_sread` / `h5fort_sread_fixed` と、Parallel の `h5fort_pwrite` / `h5fort_pread` / `h5fort_pread_fixed` である。対応する OOP type は `t_h5fort_serial` と `t_h5fort_parallel` である。

Serial の attribute は dataset、group、root group を対象にできる。手続き API の
`h5fort_write_attribute` / `h5fort_read_attribute` は generic とし、文字列に加えて
`real(real64)`、`real(real32)`、`integer(int32)`、`integer(int64)` のscalarと1D配列を扱う。
数値scalarはscalar dataspace、数値配列は要素数を長さとする1D dataspaceに保存し、
配列読み込みでは呼び出し側の配列長が一致しなければ失敗する。
`h5fort_get_attribute_info(file_id, obj_path, name, count, hdferr)` は読み込み前に属性の
要素数を `integer(int64)` で返す。文字列用OOP APIは `write_attribute` / `read_attribute`
とする。既存の複数attribute書き込みAPI `h5fort_swrite_attr` は互換性のため維持する。
dataset の `write(..., attrs=..., units=...)` は同じ文字列attribute実装へ委譲する。

`logical` はfalseを0、trueを1として `integer(int32)` に変換して保存する。
他言語との相互運用は共有仕様の[bool](https://github.com/suzuyuyuyu/h5c/blob/main/docs/FORMAT.md#データ型)を参照する。

## ファイル mode

- `H5FORTRAN_FORCE_WRITE = 1`: ファイルを truncate create する。Serial dataset write の optional mode に指定した場合は既存 dataset を置換する。
- `H5FORTRAN_READ_ONLY = 2`: 既存ファイルを read-only で開く。
- mode 省略: 既存ファイルを read-write で開く。

未設定または空の `f_name`、二重 open、二重 close は失敗し、`hdferr` を非ゼロにする。

## HDF5ライブラリのライフサイクル

`h5fortran` のOOP APIと可視化writerは `h5open_f` / `h5close_f` を内部で呼ばない。
利用者がHDF5処理全体の開始時に `h5open_f`、すべてのHDF5 objectを閉じた後に
`h5close_f` を呼ぶ。

Parallelでは全rankが `MPI_Init` 後に `h5open_f` を呼び、`h5close_f` を
`MPI_Finalize` より前に呼ぶ。ファイル単位の `%open` / `%init` / `%close` は
HDF5ライブラリ全体の開始・終了とは独立している。

## エラー契約

公開手続きは成功時に `hdferr = 0`、失敗時に非ゼロを返す。一連の処理で複数の操作が失敗した場合は、最初の非ゼロ値を保持する。後続の resource close や属性書き込みの成功で先行エラーを消してはならない。

allocatable read は dataset の rank を確認してから allocate する。fixed-size read は rank と各次元の長さが一致しない場合に失敗する。

`h5fort_get_dataset_info(file_id, path, rank, shape, hdferr)` はdatasetを読み込まず、
rankと各次元長（`integer(int64), allocatable`）を返す。

## Parallel 分割

Parallel 配列は最終次元を MPI rank 間の分割方向とする。最終次元の長さは rank ごとに異なってよく、0 も許可する。それ以外の次元は全 rank で一致しなければならず、不一致は HDF5 collective call より前に拒否する。

保存形式とrank境界は共有仕様の[Parallel の分割レイアウト](https://github.com/suzuyuyuyu/h5c/blob/main/docs/FORMAT.md#parallel-の分割レイアウト)を参照する。
Fortranの最終次元は、ファイル上では第0次元に対応する。

write時とread時の両方で、`data` の最終次元長が `__partition__` の最終値と一致する
ことを検査する。read時はさらに先頭0、単調非減少、partition長と現在のMPI process数
の一致を検査し、不一致ならreadを開始せず `hdferr` を非ゼロにする。

`__partition__` の名前は `H5FORT_DSET_PARTITION_DNAME` で変更できる。

`t_h5fort_parallel%comm` と `%info` は既定で `MPI_COMM_WORLD` と
`MPI_INFO_NULL` であり、open/read/writeに同じ値を使う。`%transfer_mode` は既定の
`H5FORTRAN_XFER_COLLECTIVE` または `H5FORTRAN_XFER_INDEPENDENT` を指定できる。
手続きAPIでは `comm=` と `transfer_mode=` のoptional引数で同じ設定を渡す。
ローカル長0のrankはfile dataspaceを`h5sselect_none_f`、memory dataspaceを
`H5S_NULL_F`で明示的に空選択する。

## Visualization HDF5 writer

`t_hdf5_writer` はローカルデータを逐次出力し、`t_phdf5_writer` は全rankのデータを
集合的に出力する。Parallel APIを有効にしたビルドでは二つの型を同時に利用できる。
どちらもXDMF/XMLを生成せず、同じ `scheme_version=1` のHDF5を出力する。

一つのビルドでは全targetが同じHDF5を使う。parallel HDF5を使う構成では、
serial targetにもHDF5由来のMPI依存がある。
serialライブラリは常にビルドされ、serial APIと `t_hdf5_writer` は常に公開される。
parallel APIと `t_phdf5_writer` は `H5FORTRAN_ENABLE_PARALLEL=ON` の場合に公開される（既定は `OFF`）。
保存レイアウトは共有仕様の[可視化レイアウト](https://github.com/suzuyuyuyu/h5c/blob/main/docs/FORMAT.md#可視化レイアウト)を参照する。
geometry は real32/real64/real128、connectivity は int8/int16/int32/int64、
point/cell data はこれら7 kindの1D・2Dに対応する。

`attribute_type=Tensor6`（成分数6）の成分順序はParaView/VTKの対称テンソル規約に合わせ、
`XX, YY, ZZ, XY, YZ, XZ` とする。利用者はこの順序で第1次元を構成しなければならない。
`h5xdmf`は成分を並べ替えない。成分順の共通規約は
[テンソル成分の順序](https://github.com/suzuyuyuyu/h5c/blob/main/docs/FORMAT.md#多成分フィールド)を参照する。

connectivityを持つmeshは `mesh_name`、XDMFの `topology_type`、
`nodes_per_element` を指定することで一般化する。既定値は
`ugrid`、`Hexahedron`、8とする。少なくとも `Tetrahedron`、
`Quadrilateral`、`Triangle` を検証対象とする。

各rankはowned cellだけを出力し、そのcellが参照する全local nodeを
`nodes(:, :)` に含める。共有・halo nodeはrank間で重複してよい。connectivityは
rank-local 0-origin IDとし、writerがrankごとのnode offsetを加えてHDF5全体のIDへ
変換する。connectivityのlocal IDが `[0, num_points)` の範囲外なら失敗する。
ghost cellは重複cellになるため出力しない。

XDMF3の生成、時系列の制約と空stepの扱いは
[POSTPROCESS.md](POSTPROCESS.md) を参照する。
