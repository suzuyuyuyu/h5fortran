# 変更履歴

## Unreleased

- Serial公開属性genericへ4種の数値型のscalar・1D配列読み書きと要素数取得を追加した。
- `h5xdmf`を独立リポジトリへ分離し、製品SemVerとHDF5 scheme versionを独立させた。

## v1.1.0

- 汎用Serial/Parallel APIへ`integer(int64)`を追加した。
- datasetのrank・shapeを取得する`h5fort_get_dataset_info`を追加した。
- Parallel APIでcommunicator、MPI_Info、collective/independent転送を選択可能にした。
- Parallel write開始時のrank間エラー判定を同期し、空rankの選択を明示した。
- `h5xdmf validate`、`--prune`、snapshotファイル名のゼロ埋め幅検査を追加した。
- 配布用CMake package/version/exportとIntel LLVM・GNU向けpresetを整備した。
- Tensor6の成分順序をXDMF 3準拠として文書化した。

## v1.0.0

- Serial / Parallel HDF5のFortranラッパーを整備した。
- 可視化用HDF5 writerとXDMF3生成ポストプロセスを追加した。
- snapshot HDF5から再生成可能な`metadata.h5`を構築する設計を採用した。

patch releaseの詳細は、同じディレクトリの日付・バージョン付きログを参照する。
