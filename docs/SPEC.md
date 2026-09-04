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

公開する手続き generic は Serial の `h5fort_swrite` / `h5fort_sread` / `h5fort_sread_fixed` と、Parallel の `h5fort_pwrite` / `h5fort_pread` / `h5fort_pread_fixed` である。対応する OOP type は `t_h5fort_serial` と `t_h5fort_parallel` である。

Serial の文字列 attribute は dataset、group、root group を対象にできる。OOP API は `write_attribute` / `read_attribute`、手続き API は `h5fort_write_attribute` / `h5fort_read_attribute` とする。既存の複数 attribute 書き込み API `h5fort_swrite_attr` は互換性のため維持する。dataset の `write(..., attrs=..., units=...)` は同じ attribute 実装へ委譲する。

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

path `P` の保存形式は次のとおりである。

- `P/data`: 最終次元方向へ連結したデータ
- `P/__partition__`: rank境界を表す長さ `writer_nprocs + 1` のint64配列

`partition(0) = 0`、rank `r` の開始位置は `partition(r)`、ローカル最終次元長は
`partition(r+1) - partition(r)`、全体長は `partition(writer_nprocs)` とする。
値は単調非減少であり、ローカル長0も表現できる。

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

## 生成物

`src/fypp/` の `.fypp` を生成元とし、`src/serial/` と `src/parallel/` の型・rank 展開済みソースは直接編集しない。fypp 3.2 を使用し、`src/fypp/generate_fypp.sh --check` で同期を検証する。

## Visualization HDF5 writer

`t_phdf5_writer` はXDMF/XMLを生成せず、`scheme_version=1` のHDF5を出力する。
root属性は `scheme_version` と `time`、mesh group属性は `topology_type` と
`nodes_per_element`、vector/tensor dataset属性は `attribute_type` とする。
geometry は real32/real64/real128、connectivity は int8/int16/int32/int64、
point/cell data はこれら7 kindの1D・2Dに対応する。

`attribute_type=Tensor6`（成分数6）の成分順序はXDMF 3に従い、
`XX, XY, XZ, YY, YZ, ZZ` とする。利用者はこの順序で第1次元を構成しなければならない。

connectivityを持つmeshは `mesh_name`、XDMFの `topology_type`、
`nodes_per_element` を指定することで一般化する。既定値は
`ugrid`、`Hexahedron`、8とする。少なくとも `Tetrahedron`、
`Quadrilateral`、`Triangle` を検証対象とする。

各rankはowned cellだけを出力し、そのcellが参照する全local nodeを
`nodes(:, :)` に含める。共有・halo nodeはrank間で重複してよい。connectivityは
rank-local 0-origin IDとし、writerがrankごとのnode offsetを加えてHDF5全体のIDへ
変換する。connectivityのlocal IDが `[0, num_points)` の範囲外なら失敗する。
ghost cellは重複cellになるため出力しない。

XDMF3は独立ツール`h5xdmf`がHDF5 metadataを読み、ポストプロセスとして生成する。
時系列中に空stepがあるmeshについては、XDMFの各stepをSpatial Collectionで包み、
非空stepだけにUniform Gridを置く。空stepからゼロサイズHDF5 DataItemを参照しない。
これはXDMF表現上の互換対策であり、HDF5 schemaや粒子数を変更しない。

各snapshot内のdatasetは固定サイズとする。step間ではnode数、element数、粒子数が
変化してよい。ソルバーは中央の `metadata.h5` へ追記せず、Python indexerが
snapshot HDF5をmetadata-onlyで走査してmanifestを構築する。`metadata.h5` は
snapshotから再構築可能な索引であり、Python側ではUNLIMITED datasetを使用して
未登録stepを増分追記する。

mesh名、topology、nodes per element、field構成、dtype、centeringは同じrunの
時系列を通して固定する。time、node数、element数はstepごとに変化できる。
MPI rankごとの範囲はHDF5内で連結済みの1つの論理meshとして扱い、
`metadata.h5` では空間分割しない。同一mesh名の複数空間ブロックとAMRは
scheme v1の対象外とする。

詳細は [POSTPROCESS.md](POSTPROCESS.md) を参照する。
