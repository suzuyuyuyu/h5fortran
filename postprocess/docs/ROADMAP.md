# h5xdmf roadmap

## 現在の完成範囲

現在の対象が次の範囲であれば、主要機能は揃っている。

- 1 time step = 1 HDF5 file
- HexahedronによるUnstructuredGrid
- connectivityを持つ任意のXDMF topology
- 検証済み: Tetrahedron、Quadrilateral、Triangle
- Polyvertexによる粒子データ
- point/cell data
- HDF5 metadataの索引化
- `metadata.h5` の増分更新
- 時系列XDMF3の生成

新機能は先回りして増やさず、実データや運用上の必要性が確認されてから追加する。

## 優先候補

### 1. HDF5 schema validation

追加する場合の第一候補は `h5xdmf validate` とする。

検査対象:

- root属性 `scheme_version` と `time`
- mesh属性 `topology_type` と `nodes_per_element`
- geometry、connectivity、point/cell dataのshape
- fieldのentity数
- connectivityのindex範囲
- `attribute_type` と成分数の整合性
- time series間で不変とするfield、dtype、centeringの整合性

これは新しい出力機能ではなく、FortranとPythonの間のHDF5 schema契約を確認し、
問題のあるHDF5をXDMF生成前に分かりやすく報告するための機能である。

### 2. 安全なmanifest更新

計算とpostprocessを並行実行する必要が生じた場合に検討する。

- 一時ファイルへ書いてから `metadata.h5` を置換するatomic update
- 複数processから更新される場合のfile lock
- 書き込み途中のsnapshotを読み込まないための完了marker

### 3. 欠損・削除stepへの対応

HDF5 snapshotを後から削除・移動する運用が発生した場合に、manifestから存在しない
stepを除外する `--prune` を検討する。

### 4. provenance metadata

再現性のために必要になった場合は、HDF5 root属性として次を保存する。

- solver名とversion
- source codeのGit commit
- 単位系
- 座標系
- 計算条件またはcase ID

XDMF生成に不要な情報は必須schemaには含めない。

## 現時点では追加しないもの

明確な利用要求がない限り、次の機能は追加しない。

- GUI
- 常駐監視daemon
- plugin機構
- 複雑な設定ファイル
- 多数の細分化されたCLI subcommand
- HDF5 field本体の変換・複製
- Fortran側でのXDMF/XML生成
- 同一mesh名の空間ブロック分割とAMR

同一論理meshを複数の空間ブロックとしてXDMFへ渡す必要が実際に生じた場合は、
現在の単一meshモデルを暗黙に拡張せず、h5xdmf Version 0.2としてmetadata schemaを
追加する。

## 方針

当面は現在の機能を安定させる。次に実装する可能性が最も高い機能は
`h5xdmf validate` だが、実際の出力で検証不足が問題になった時点で着手する。
