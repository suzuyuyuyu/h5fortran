# Visualization output example

2 MPI rank、5 output stepの小さな流体・土粒子計算を模擬し、Fortranによる
snapshot HDF5出力からPythonによるmanifest・XDMF生成までを実行する。

## 生成される構成

```text
result/
├── seq000000.h5
├── seq000001.h5
├── seq000002.h5
├── seq000003.h5
├── seq000004.h5
├── metadata.h5
├── fluid.xdmf
└── soil_particles.xdmf
```

各snapshotには次の2つのmesh groupが入る。

```text
seqNNNNNN.h5
├── /fluid
│   ├── geometry/nodes
│   ├── geometry/connectivity
│   ├── point_data/Pressure
│   ├── point_data/Velocity
│   ├── point_data/Speed
│   └── cell_data/SubdomainID
└── /soil_particles
    ├── geometry/nodes
    ├── point_data/Velocity
    ├── point_data/EquivalentStress
    └── point_data/ParticleID
```

`fluid` は `8 × 4 × 3` の直方体領域を576個のTetrahedronへ分割したmeshである。
hydrostatic gradientへ進行波を重ねた `Pressure`、時間変化する渦状の `Velocity`、
その大きさ `Speed` を持つ。

`soil_particles` は初期状態で約96点のPolyvertexである。粒子層が沈降しながら
水平方向へ広がり、深さとともに `EquivalentStress` が増加する。流出を模擬して
粒子数もstepごとに減少する。

## 実行

最初にParallel HDF5を使ってCMakeをconfigureする。

```sh
cmake -S . -B build \
  -DCMAKE_Fortran_COMPILER=mpiifx \
  -DHDF5_ROOT=/path/to/parallel-hdf5
```

リポジトリrootから次を実行する。

```sh
example/visualization/generate.sh build
```

build directoryを省略すると、リポジトリrootの `build/` を使用する。

```sh
example/visualization/generate.sh
```

MPI launcherとrank数は環境変数で変更できる。

```sh
MPIEXEC=mpiexec NPROCS=4 example/visualization/generate.sh build
```

生成後はParaViewで次を個別に開く。

```text
example/visualization/result/fluid.xdmf
example/visualization/result/soil_particles.xdmf
```

両方を同時に読み込めば、流体meshと土粒子を重ねて表示できる。

## ParaViewでの見方

1. `fluid.xdmf` と `soil_particles.xdmf` を開いて両方に `Apply` する。
2. fluidを `Pressure` または `Speed` で色付けする。
3. 内部を確認する場合はfluidへ `Clip` または `Slice` filterを適用する。
4. `Velocity` を見る場合は `Glyph` filterを追加し、Orientation Arrayを
   `Velocity`、Scale Arrayを `Speed` にする。
5. soil particlesは `EquivalentStress` で色付けする。点が小さい場合は
   Representationを `Point Gaussian` にするか、`Glyph` でsphereを表示する。
6. animationを再生すると、圧力波・渦速度・粒子層の沈降と広がりを確認できる。

fluid meshはMPI rank境界のnodeをrankごとに重複して出力している。境界nodeを一つに
まとめて表示・処理したい場合は、fluidへ `Clean to Grid` filterを適用する。
connectivityはexample内ではrank-local 0-origin IDで作成し、writerがHDF5全体の
node offsetを加えている。

## ポストプロセスだけ再実行

```sh
cd postprocess
uv run h5xdmf "../example/visualization/result/seq*.h5" \
  --metadata ../example/visualization/result/metadata.h5 \
  --outdir ../example/visualization/result \
  --rebuild
```
