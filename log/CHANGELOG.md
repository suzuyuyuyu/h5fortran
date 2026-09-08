# 変更履歴

## v2.0.0

4 リポジトリでバージョンを揃えた。`scheme_version` は 1 のままで、
これまでに書いた HDF5 はそのまま読める。

**破壊的変更**：`H5FORTRAN_ENABLE_SERIAL` を撤廃したため、これを `OFF` に
していた構成は無視される。逐次 API は常に構築される。

- Serial APIを常時ビルド・公開するようにし、逐次APIの有効化オプションと条件付きマクロを削除した。
- 可視化writerをserial型とそれを継承するparallel型に分離し、同一ビルドでの併用と共通レイアウトを検証するテストを追加した。
- `Tensor6`の成分順序の文書を、ParaView/VTKの`XX, YY, ZZ, XY, YZ, XZ`へ訂正した。
- Serial公開属性genericへ4種の数値型のscalar・1D配列読み書きと要素数取得を追加した。
- `h5xdmf`を独立リポジトリへ分離し、製品SemVerとHDF5 scheme versionを独立させた。
- 可視化のexampleを`serial-viz/`と`parallel-viz/`に分離した。
- `stdout/`と`stderr/`をリポジトリに残すようにした。従来はクローン直後にジョブが出力なしで即座に失敗していた。

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

v1.0.1の検証経緯は [当時のログ](v1.md) を参照する。
