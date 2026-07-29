# 構造・実装レビュー

最終確認日: 2026-07-29

## 現在の構造

- `src/fypp/`: Serial/Parallel APIの生成元
- `src/serial/`, `src/parallel/`: fyppで生成されたビルド対象Fortran
- `src/h5fort.F90`: Serial/Parallel公開APIのfacade
- `test/`: Serial、Parallel、Visualization HDF5、install consumerのテスト
- `example/`: Serial、Parallel、可視化出力の利用例
- `postprocess/`: snapshot HDF5の索引化とXDMF3生成を行うPython package
- `docs/`: API、可視化schema、ポストプロセス、テスト、TODO

生成元と生成物は次で同期を確認する。

```sh
src/fypp/generate_fypp.sh
src/fypp/generate_fypp.sh --check
```

## 現在の設計判断

### FortranとPythonの責務

Fortranソルバーは1 output stepにつき1つの `seqNNNNNN.h5` を出力する。snapshot
HDF5がfield値とmetadataの正本である。

Pythonはsnapshotをmetadata-onlyで走査し、再生成可能な索引 `metadata.h5` を作る。
ソルバーから中央manifestへUNLIMITED追記する方式は採用しない。

理由:

- ソルバーのcritical pathを単純に保つ
- snapshotとmanifestの二重書き込みによる不整合を避ける
- MPIから中央HDF5を毎step拡張する実装を不要にする
- manifestをsnapshotから復旧できる

### XDMF

Fortran側のXDMF/XML生成は廃止した。Pythonが `metadata.h5` を読み、mesh group名ごと
に時系列XDMFを生成する。標準構成は流体と土粒子を分ける。

```text
fluid.xdmf
soil_particles.xdmf
```

XDMFはfield本体を保持せず、snapshot HDF5をHeavy Dataとして参照する。

### Mesh

connectivityを持ち、1要素当たりのnode数が固定なら、`topology_type` と
`nodes_per_element` により一般化して扱う。

検証済み:

- Hexahedron
- Tetrahedron
- Quadrilateral
- Triangle
- Polyvertex

XDMF `Mixed` topologyは未対応である。

### 時系列の可変性

同じmesh名について、topology、nodes per element、field構成、dtype、centeringは
時系列を通して固定する。node数、element数、粒子数、timeはstepごとに変化できる。

各snapshot内のdatasetは固定サイズであり、stepごとに別ファイルへ出力することで
entity数の変化を扱う。Fortranの汎用UNLIMITED append APIは可視化metadataには
使用しない。

### MPI境界のnode

各rankはowned cellと、それらが参照する全local nodeを出力する。共有・halo nodeは
rankごとに重複してよく、connectivityはrank-local 0-origin IDでwriterへ渡す。
writerがglobal output offsetを加えるため、node番号統合の事前通信は不要である。
ghost cellは出力しない。重複nodeを結合する場合はParaViewの `Clean to Grid` を
利用する。共有nodeのfield値を一致させる必要がある場合だけ、出力前にhalo exchangeを
行う。

## 確認済み

- fypp 3.2によるSerial/Parallelソース生成と同期確認
- clean CMake configure/build
- Serial-only build
- Intel MPI Fortran + Parallel HDF5 build
- Serial read/write、属性、エラー契約
- Parallel read/write、0要素rank、shape/rank検査、OOP API
- Visualization HDF5の2-rank出力
- 複数mesh groupと一般化topology
- Python manifestの新規作成と増分更新
- Python XDMF生成とCLI
- install後の外部consumer build
- Fortran snapshotからXDMFまでのend-to-end example

実行方法は [TEST.md](TEST.md) を参照する。

## 残る課題

優先度は [TODO.md](TODO.md) と
[`postprocess/docs/ROADMAP.md`](../postprocess/docs/ROADMAP.md) を参照する。

特に実運用前に検討するもの:

- 書き込み途中のsnapshotをindexerが開かない完了方式
- HDF5 schemaの明示的なvalidation
- snapshot削除・移動後のmanifest更新
- 大量ファイル環境におけるmetadata-only走査時間の計測
