# h5xdmf

HDF5 出力（Fortran ソルバ, MPI-IO, 1 step = 1 file）から可視化用の **XDMF3** を
生成するツール。HDF5 のレイアウトは `scheme_version` 属性で切り替え可能。

設計は [`docs/design.md`](docs/design.md)、将来機能の判断方針は
[`docs/ROADMAP.md`](docs/ROADMAP.md) を参照。

## セットアップ

```sh
uv sync
```

## 使い方

HDF5時系列を索引化して `metadata.h5` とmesh別XDMFを生成します。

```sh
uv run h5xdmf "phdf5/seq*.h5" --metadata metadata.h5 --outdir xdmf
```

同じコマンドの再実行は新しいstepだけをmanifestへ追記します。全再構築は
`--rebuild`、既存manifestからXDMFだけを再生成する場合は
`--generate-only --metadata metadata.h5` を使います。

粒子数などが0になるstepは、子Gridを持たないSpatial CollectionとしてXDMFへ
出力される。HDF5の空datasetは保持されるが、XDMFからは参照しない。

Python API:

```python
from h5xdmf import sample
from h5xdmf.hdf5 import read_series_glob

# 合成データを生成（seq00000.h5 ...）
sample.write_series("phdf5", nsteps=5)

# メタデータだけ読み込む（XDMF 生成に必要な情報）
series = read_series_glob("phdf5/seq*.h5", load_data=False)
for snap in series:
    print(snap.name, snap.time, [b.name for b in snap.mesh_blocks])
```

## テスト

```sh
uv run pytest
```
