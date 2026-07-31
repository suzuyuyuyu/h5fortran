# h5xdmf 設計メモ

HDF5（FortranソルバーがMPI-IOで出力、1 step = 1 file `seqNNNNNN.h5`）から
可視化用の XDMF3 を生成する。HDF5 の出力レイアウトは未確定のため、ファイル
ルートの `scheme_version` 属性でレイアウトを切り替えられるようにする。

## データフロー

```
Fortran solver ──(MPI-IO)──> result/seqNNNNNN.h5   (root attr: scheme_version, time)
                                   │
                            [hdf5.reader]  scheme_version → Scheme を解決し委譲
                                   │  load_data=False（shape/dtype/attrs のみ）
                                   ▼
                            [indexer]  各ファイルを 1 回だけ走査
                                   ▼
                            metadata.h5  (manifest: 不変スキーマ + 毎ステップの可変量)
                                   ▼
                            [xdmf builder]  → <mesh_name>.xdmf (Temporal Collection)
```

- **要点**: XDMF生成は `metadata.h5` だけを参照し、`seqNNNNNN.h5` を一切開かない。
  「時刻や配列サイズのために全 seq を読む」コストを、indexer の 1 回の
  metadata-only 走査に閉じ込める。値（フィールド本体）はどの段でも読まない。
- `reader` は `load_data=False` でメタデータ（shape/dtype/h5path）だけを読む。
  h5py は shape/dtype/attrs を配列本体をロードせずに返すので、走査は軽量。
- `writer` はテスト用フィクスチャ生成に使う（本番の書き手は Fortran 側）。
  scheme を共有することでレイアウトの一致を保証する。

### なぜマニフェストを挟むか

`time` はstepごとに全snapshotへ分散しており、後から回収するとNファイル分の
metadata I/Oになる。一方、XDMFが必要とするもののうち
**dtype・field集合・centering・topologyは不変**で、変わるのは
**entity数（粒子数を含む）と時刻**だけである。
そこで不変スキーマを 1 回、可変量を毎ステップ、という形で `metadata.h5` に
集約し、XDMF 生成を「マニフェストのみ・値ロードなし」で完結させる。

## 中間モデル (`model.py`)

XDMF の語彙に合わせてあり、後段の XDMF 生成を単純化する。

| クラス | 意味 |
|--------|------|
| `DataArray` | 1 フィールド。center(Node/Cell), attr_type(Scalar/Vector/Tensor6/Tensor), h5path, shape, dtype |
| `MeshBlock` | 1 メッシュ。name, topology_type, nodes, connectivity, point_data[], cell_data[] |
| `Snapshot`  | 1 時刻 = 1 ファイル。time, mesh_blocks[] |
| `Series`    | Snapshot の時系列 |

## scheme_version による分岐 (`schemes/`)

レイアウトの知識は `schemes/` にのみ置く。reader/writer/model は scheme 非依存。

- `base.Scheme` — 抽象基底。`read_snapshot` / `write_snapshot` / `read_time` を定義。
  型推論（shape → AttributeType）や `DataArray` 構築などの共通ヘルパを提供。
- `v1.py` — `scheme_version=1`。サンプル XDMF 互換のレイアウト。
- `__init__.py` — `scheme_version → Scheme` のレジストリ。`get_scheme(version)`。

新しい出力形式へは `schemes/vN.py` を追加してレジストリ登録するだけで対応でき、
他のレイヤーは変更不要。

### scheme_version = 1 のレイアウト

```
/                                 attrs: scheme_version=1, time=<float64>
/<mesh>/                          attrs: topology_type, nodes_per_element
/<mesh>/geometry/nodes            (num_nodes, 3)  float
/<mesh>/geometry/connectivity     (num_elements, npe) int   [任意: 点群では省略]
/<mesh>/point_data/<Name>         (num_nodes[, ncomp])
/<mesh>/cell_data/<Name>          (num_elements[, ncomp])
```

- メッシュブロック = `geometry` サブグループを持つルート直下グループ。
- フィールドの rank は、データセット属性 `attribute_type` があればそれを優先し、
  無ければ末尾次元数から推論（1→Scalar, 3→Vector, 6→Tensor6, 9→Tensor）。
  Fortran 側が属性を付けられない場合でも読めるようにするための二段構え。
- scheme は論理座標（mesh 名・field 名・centering）→ 物理 h5path の解決も担う
  (`mesh_group_h5path` / `nodes_h5path` / `connectivity_h5path` / `field_h5path`)。
  manifest / XDMF 層はパス文字列を持たず、規約は scheme に一元化される。

## マニフェスト (`manifest.py`, `metadata.h5`)

scheme v1では、root直下の各mesh groupを1つの完全な論理meshとして索引化する。
MPI rankごとの配列はFortran writerがHDF5 dataset内で連結済みであり、manifestでは
空間的に分割しない。

```
/                                  attrs: scheme_version,
                                           format="h5xdmf-manifest/1",
                                           mesh_order[]
/timeseries/
    time              (N,) f8        毎step追記
    file              (N,) str       snapshotの相対パス
/meshes/<mesh_name>/                 meshごとの不変schema
    attrs: topology_type, nodes_per_element, field_order[]
    geometry                         nodes/connectivityのdtype
    fields/<Name>                    center、attribute_type、dtype
    timeseries/
        step_index      (M,) i8      /timeseriesを参照
        num_nodes       (M,) i8      stepごとの節点数
        num_elements    (M,) i8      stepごとの要素数または粒子数
```

- `/timeseries` は計算全体のstepとsnapshotファイルを1対1で保持する。
- meshごとの `timeseries` は可変長であり、通常は `M == N`。`step_index` により
  meshが存在しないstepも表現できる。
- `num_nodes` / `num_elements` はmeshごとに保持するため、流体meshと粒子で異なる
  entity数や、step間の粒子数変化を記録できる。
- 同じmesh名を複数空間ブロックへ分ける機能とAMRはscheme v1に含めない。
  必要になった時点でh5xdmf Version 0.2としてmetadata schemaを追加する。
- connectivityのrank offsetはmanifestの責務ではない。Fortran writerがHDF5への
  書き込み前に計算し、各rankのlocal connectivityをglobal indexへ変換する。

### indexer / xdmf builder

- `indexer.build_manifest`: seqを `load_data=False` で1回走査してmanifest構築。
  不変であるべき項目（topology、nodes per element、field集合、dtype、centering）は
  初出で確定し、以降のstepで一致を検証する。entity数とtimeはstepごとに可変。
- `indexer.update_manifest`: 既存 `metadata.h5` を**増分更新**。まだ記録されていない
  seq だけを走査し、拡張可能データセット（`maxshape=(None,)`）を `resize` して末尾に
  追記する（`manifest.append_manifest`）。既存の行は書き換えない。追記対象のmeshは
  ファイル内の既存スキーマと照合（不一致はエラー、新規meshは登録）。同じ入力での
  再実行は no-op。ファイルが無ければ新規構築にフォールバック。
- `xdmf.build_xdmf_files`: **mesh group名ごとに1つの `<name>.xdmf`** を出力
  （Temporal Collection）。標準例では `fluid.xdmf` と
  `soil_particles.xdmf` になる。参照パスは `.xdmf` の場所からの相対に変換する。
- node数またはelement数が0のrecordを含むmeshは、全stepをSpatial Collectionで
  包んで出力する。非空stepの子はUniform Grid 1個、空stepは子Grid 0個とする。
  これにより出力データ型を時系列内で揃え、ゼロサイズHDF5 DataItemをXDMFから
  参照しない。logical meshやmanifest schemaを空間分割へ拡張するものではない。

## ディレクトリ構成

```
src/h5xdmf/
├── model.py            中間モデル
├── manifest.py         マニフェスト（metadata.h5 の read/write）
├── indexer.py          seq 群 → マニフェスト（metadata-only 走査 + 不変性検証）
├── schemes/            scheme_version ごとのレイアウト定義 + h5path 解決
│   ├── base.py / __init__.py / v1.py
├── hdf5/               scheme 非依存の I/O
│   ├── io.py / reader.py / writer.py
├── sample.py           合成データ生成（hex + 粒子）
└── xdmf/               manifest → XDMF3（mesh ごと）
    └── builder.py
```

## CLIと運用

`h5xdmf` CLIがmanifestの新規作成・増分更新とXDMF生成をまとめて実行する。

```sh
uv run h5xdmf "../result/seq*.h5" \
  --metadata ../result/metadata.h5 \
  --outdir ../result
```

snapshot HDF5を正本とし、Fortranソルバーは `metadata.h5` へ直接追記しない。
`metadata.h5` はPythonが管理する再生成可能な索引とする。完成形と運用上の注意は
ルートの [`docs/POSTPROCESS.md`](../../docs/POSTPROCESS.md) を参照する。
