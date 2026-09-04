# 可視化用Parallel HDF5出力

`t_phdf5_writer` は全MPI rankのmeshとfieldを一つのHDF5ファイルへ集合的に
書きます。Fortran側ではXDMF/XMLを生成しません。HDF5時系列を出力した後、
独立ツール[`h5xdmf`](https://github.com/suzuyuyuyu/h5xdmf)でXDMF3を生成します。

snapshot HDF5を正本とし、`metadata.h5` はPythonが作る再生成可能な索引とする。
ソルバーは `metadata.h5` へ追記しない。

想定する完成形:

```text
result/
├── seq000000.h5
├── seq000001.h5
├── ...
├── metadata.h5
├── fluid.xdmf
└── soil_particles.xdmf
```

## HDF5出力

```fortran
use hdf5, only: h5open_f, h5close_f
use h5fort
use mpi
use iso_fortran_env, only: int64, real64

type(t_phdf5_writer) :: writer
integer :: ierr, hdferr
real(real64) :: nodes(3, num_points)
integer(int64) :: connectivity(8, num_cells)
real(real64) :: pressure(num_points)
real(real64) :: velocity(3, num_points)

call MPI_Init(ierr)
call h5open_f(hdferr)
if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)

writer%h5_filepath = 'result/seq000000.h5'
writer%output_type = 'UnstructuredGrid'
writer%num_points = num_points
writer%num_cells = num_cells
writer%time = 0.0_real64

call writer%init()
call writer%write_geometry_ugrid(nodes, connectivity)
call writer%write_point_data(pressure, 'Pressure')
call writer%write_point_data(velocity, 'Velocity')
call writer%close()

call h5close_f(hdferr)
if (hdferr /= 0) call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
call MPI_Finalize(ierr)
```

`num_cells` は各rankが出力するowned cell数で、ghost cellは含めません。
`num_points` はowned cellが参照する全local node数です。rank境界の共有・halo nodeは
rankごとに別nodeとして重複して構いません。

connectivityは `nodes(:, :)` を参照するrank-local 0-origin node IDで渡します。
writerがrankごとのnode offsetを加え、HDF5全体のIDへ変換します。呼び出し側で
global node IDを計算するための通信は不要です。`init`、write、`close` は全rankが
同じ順序で呼びます。

writerはHDF5ライブラリ自体の開始・終了を行いません。全rankがプログラム全体で
`MPI_Init` → `h5open_f` → writer処理 → `h5close_f` → `MPI_Finalize` の順に
呼びます。複数stepや複数meshを書いても、`h5open_f` / `h5close_f` はそれぞれ
1回だけです。

```fortran
! nodes(:, 1:4) を参照するrank-local connectivity
connectivity(:, 1) = [0_int64, 1_int64, 2_int64, 3_int64]
call writer%write_geometry(nodes, connectivity)
```

共有nodeのfield値を一致させて可視化したい場合、必要に応じて出力前に通常のhalo
exchangeを行います。これはnode番号を統合する通信ではなく、field値を同期するための
通信です。

重複nodeを結合したい場合はParaViewの `Clean to Grid` filterを利用できます。
ghost cellまで出力するとcellが重複するため、出力対象はowned cellだけにします。

PolyDataは `output_type='PolyData'`、`num_cells=0` として
`write_geometry_polydata(nodes)` を呼びます。同じ `h5_filepath` に
UnstructuredGrid、PolyDataの順で書くと、`/ugrid` と `/polydata` に保存されます。

## Connectivity meshの一般形

connectivityを持つmeshは、同じwriterで任意のXDMF topologyを扱えます。
`mesh_name` はHDF5のroot直下group名です。

```fortran
writer%h5_filepath = 'result/seq000000.h5'
writer%output_type = 'UnstructuredGrid'
writer%mesh_name = 'tetra'
writer%topology_type = 'Tetrahedron'
writer%nodes_per_element = 4
writer%num_points = num_points
writer%num_cells = num_cells
writer%time = time

call writer%init()
call writer%write_geometry(nodes, connectivity)
call writer%write_point_data(pressure, 'Pressure')
call writer%close()
```

代表的な指定は次のとおりです。

| 要素 | `topology_type` | `nodes_per_element` |
|---|---|---:|
| 六面体 | `Hexahedron` | 8 |
| 四面体 | `Tetrahedron` | 4 |
| 2D四角形 | `Quadrilateral` | 4 |
| 三角形 | `Triangle` | 3 |

`topology_type` と `nodes_per_element` は同時に指定します。省略した場合だけ
`Hexahedron`、8が既定値になります。同じHDF5へ異なる `mesh_name` で順番に
書き込むことで、複数種類のmeshを一つのtime stepに保存できます。

## scheme_version=1

```text
/                                      attrs: scheme_version=1, time=<float64>
/<mesh>/                               attrs: topology_type, nodes_per_element
/<mesh>/geometry/nodes                 (num_nodes, 3)
/<mesh>/geometry/connectivity          (num_elements, npe), PolyDataでは省略
/<mesh>/point_data/<field>             (num_nodes[, ncomp])
/<mesh>/cell_data/<field>              (num_elements[, ncomp])
```

2D fieldには `attribute_type=Vector|Tensor6|Tensor` 属性も書かれます。対応成分数は
3、6、9です。1D fieldは `Scalar` です。

geometryは `real(real32/real64/real128)`、connectivityは
`integer(int8/int16/int32/int64)`、point/cell dataはこれら7 kindの1D/2Dに
対応します。

## XDMFの生成

Python 3.10以上と`uv`を用意し、h5xdmfをインストールして実行します。

```sh
uv tool install ../h5xdmf
h5xdmf "result/seq*.h5" --metadata result/metadata.h5 --outdir result
```

初回は各snapshotのmetadataだけを一度走査して `metadata.h5` を作ります。
再実行時は未登録のsnapshotだけを追記します。XDMF生成はmanifestだけを読み、
field本体やsnapshot HDF5を再走査しません。

XDMFはmesh group名ごとに生成される。HDF5 groupを `/fluid` と
`/soil_particles` にすると、`fluid.xdmf` と `soil_particles.xdmf` になる。
field本体はXDMFへ複製されず、各 `seqNNNNNN.h5` のdatasetを参照する。

粒子数が途中で0になる場合もHDF5には0件のdatasetをそのまま保存する。生成XDMFでは
空stepを子GridのないSpatial Collectionとして表し、ゼロサイズdatasetを参照しない。
非空stepでは通常のUniform GridがSpatial Collectionの子になる。全stepが非空のmesh
は従来どおりUniform Gridの時系列として出力される。

`metadata.h5` のmesh別時系列構造と増分更新の詳細は
[POSTPROCESS.md](POSTPROCESS.md) を参照してください。

## 完成形のexample

2 MPI rank、5 stepの流体・土粒子snapshot出力からポストプロセスまでを一括実行
できます。流体は四面体mesh上の圧力波と渦速度、土粒子は沈降・拡散と応力を持つ。

```sh
example/visualization/generate.sh build
```

生成されるファイルと使い方は
[`example/visualization/README.md`](../example/visualization/README.md) を参照してください。
ParaViewでの色付け、Glyph、粒子表示の手順もexample READMEに記載している。

必要な実行時ツールはPython 3.10以上、`h5py`、`numpy`です。依存関係と固定版は
`pyproject.toml` と `uv.lock` で管理されています。生成XDMFの確認にはParaView、
HDF5構造の手動確認には `h5dump` または `h5ls` が便利ですが、どちらも生成処理の
必須依存ではありません。
