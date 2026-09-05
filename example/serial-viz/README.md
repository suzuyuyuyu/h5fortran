# Serial visualization output example

1プロセス、5 output stepの小さな流体・土粒子計算を模擬し、Fortranによる
snapshot HDF5出力からPythonによるmanifest・XDMF生成までを実行する。

1プロセスの出力には、この例の `t_hdf5_writer` を使う。MPIの初期化は不要である。
複数MPI rankのデータを一つのファイルへ集合的に出力する場合には
[`parallel-viz/`](../parallel-viz/README.md) の `t_phdf5_writer` を使う。
両者のmesh・field名とファイルレイアウトは共通である。

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

`fluid` は `4 × 4 × 3` の全直方体領域を288個のTetrahedronへ分割したmeshである。
並列例の1 rank分に相当する100節点のmeshを直接作成する。
hydrostatic gradientへ進行波を重ねた `Pressure`、時間変化する渦状の `Velocity`、
その大きさ `Speed` を持つ。

`soil_particles` は初期状態で48点のPolyvertexである。粒子層が沈降しながら
水平方向へ広がり、深さとともに `EquivalentStress` が増加する。流出を模擬して
粒子数もstepごとに減少する。

## 実行

最初に独立ツール`h5xdmf`をインストールし、Serial HDF5を使ってCMakeをconfigureする。

```sh
uv tool install ../h5xdmf
```

```sh
cmake -S . -B build \
  -DCMAKE_Fortran_COMPILER=ifx \
  -DHDF5_ROOT=/path/to/serial-hdf5 \
  -DH5FORTRAN_ENABLE_PARALLEL=OFF \
  -DH5FORTRAN_BUILD_EXAMPLES=ON
```

リポジトリrootから次を実行する。

```sh
example/serial-viz/generate.sh build
```

build directoryを省略すると、リポジトリrootの `build/` を使用する。

```sh
example/serial-viz/generate.sh
```

`generate.sh` は `example_serial_viz` をビルドして直接実行する。
出力は `result/seq000000.h5` から `seq000004.h5` の5ファイルである。

生成後はParaViewで次を個別に開く。

```text
example/serial-viz/result/fluid.xdmf
example/serial-viz/result/soil_particles.xdmf
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

connectivityは全meshのnodeを参照する0-origin IDで作成する。

## ポストプロセスだけ再実行

```sh
h5xdmf "example/serial-viz/result/seq*.h5" \
  --metadata example/serial-viz/result/metadata.h5 \
  --outdir example/serial-viz/result \
  --rebuild
```
