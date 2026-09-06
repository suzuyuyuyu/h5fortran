# ポストプロセス

## 方針

Fortranソルバーが出力する各stepのsnapshot HDF5を正本とし、`metadata.h5` は
Pythonポストプロセスが構築する再生成可能な索引とする。

```text
Fortran solver
    ├── result/seq000000.h5
    ├── result/seq000001.h5
    └── result/seq000002.h5
              │ metadata-only走査
              ▼
         result/metadata.h5
              │
              ├── result/fluid.xdmf
              └── result/soil_particles.xdmf
```

ソルバーは `metadata.h5` を更新しない。

## ファイルの責務

### `seqNNNNNN.h5`

Fortranソルバーが1 output stepにつき1ファイル出力する。field本体、geometry、
connectivityと、そのファイルを解釈するためのmetadataを保持する。

保存レイアウトは共有仕様の[可視化レイアウト](https://github.com/suzuyuyuyu/h5c/blob/main/docs/FORMAT.md#可視化レイアウト)を参照する。

ファイル名の数字部分の桁数は固定しない。ただしglobを辞書順に並べるため、同じrun内
ではゼロ埋め桁数を統一する。標準例では6桁の `seqNNNNNN.h5` を使用する。

### `metadata.h5`

Pythonのindexerがsnapshot HDF5のshape、dtype、属性、pathだけを読み、field本体を
ロードせずに作成する。削除または破損してもsnapshot HDF5から再構築できる。

初回は指定されたsnapshotを走査する。再実行時は未登録のsnapshotだけを読み、
索引へ追記する。同じ入力での再実行はno-opである。

時系列を通して固定するもの:

- mesh名とHDF5 group path
- topologyとnodes per element
- field名と順序
- dtype
- Node/Cell centering
- Scalar/Vector/Tensor種別

stepごとに変化できるもの:

- snapshot HDF5ファイル名
- time
- node数
- element数または粒子数

### XDMF

XDMFはfield値を複製せず、`seqNNNNNN.h5` 内のdatasetをHeavy Dataとして参照する。
現在はmesh group名ごとに1つの時系列XDMFを生成する。

時系列中にnode数またはelement数が0のstepがあるmeshは、各stepをSpatial
Collectionで包む。非空stepにはUniform Gridを1つ置き、空stepは子Gridを持たない
空のSpatial Collectionとする。これにより、粒子が消滅する時系列を正確に表現しつつ、
ParaViewがゼロサイズHDF5 DataItemを時間更新時に再読込する経路を避ける。
HDF5 snapshotと`metadata.h5`の粒子数は変更しない。

標準的な物理区分は次の2つである。

```text
fluid.xdmf
soil_particles.xdmf
```

流体meshと土粒子をParaViewで個別に開くことができ、両方を読み込めば重ねて表示
できる。

meshが存在しないstepも扱える。scheme v1は同じmesh名の複数空間ブロックやAMRを扱わない。
粒子数は索引の `/meshes/<mesh_name>/timeseries/num_elements` で確認できる。

## 実行

```sh
h5xdmf "result/seq*.h5" --metadata result/metadata.h5 --outdir result
```

- 通常実行: 新しいsnapshotだけをmanifestへ追加してXDMFを生成
- `--rebuild`: `metadata.h5` を最初から再構築
- `--generate-only`: snapshotを走査せず、既存manifestからXDMFだけを再生成
- `--prune`: 存在しないsnapshotをmanifestから除外してstep indexを詰め直す

snapshotのschemaだけを検査する場合は次を実行する。

```sh
h5xdmf --check "result/seq*.h5"
```

## 完成形のexample

5 stepの流体・土粒子出力は[逐次例](../example/serial-viz/README.md)と
[並列例](../example/parallel-viz/README.md)を参照する。
各例の `result/` にsnapshot、`metadata.h5`、mesh別XDMFを生成する。
並列例はクラスタのジョブスクリプトから実行する。

## 運用上の注意

- 書き込み途中のsnapshotをindexerが読まないようにする。
- 実運用では一時名へ出力し、close後に最終的な `.h5` 名へrenameする方法を推奨する。
- `metadata.h5` は索引なのでバックアップ必須ではないが、再走査を避けるため通常は保持する。
- snapshotを同じファイル名で上書きした場合、既存manifestは自動再索引化しない。
- snapshotを削除した場合は`--prune`でmanifestから明示的に除外する。
- XDMF `Mixed` topologyは未対応である。
