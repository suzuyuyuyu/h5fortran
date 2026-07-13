# Parallel HDF5 / XDMF 出力

`t_phdf5_writer` は、全 MPI rank の mesh と属性を一つの HDF5 ファイルへ集合的に書き、ParaView などから参照する XDMF fragment を生成します。

## 対応型

geometry の座標は `real(real32/real64/real128)`、connectivity は `integer(int8/int16/int32/int64)` に対応します。point/cell data は次のすべてについて 1D scalar と 2D vector/tensor を書けます。

- `integer(int8)`、`integer(int16)`、`integer(int32)`、`integer(int64)`
- `real(real32)`、`real(real64)`、`real(real128)`

XDMF の `NumberType` と `Precision` は、書き込んだ Fortran kind から自動設定されます。従来の `add_point_attr` / `add_cell_attr` も互換性のため利用できますが、通常は明示的に呼ぶ必要はありません。

## UnstructuredGrid

```fortran
use h5fort
use mpi
use iso_fortran_env, only: int64, real64

type(t_phdf5_writer) :: writer
real(real64) :: nodes(3, num_points)
integer(int64) :: connectivity(8, num_cells)
real(real64) :: pressure(num_points)
real(real64) :: velocity(3, num_points)

writer%h5_filepath = 'phdf5/seq00000.h5'
writer%h5_filename = 'seq00000.h5'
writer%metadata_dir = 'metadata'
writer%rel_dir_meta2h5 = '../phdf5'
writer%output_type = 'UnstructuredGrid'
writer%num_points = num_points
writer%num_cells = num_cells
writer%seq = 0
writer%time = 0.0_real64

call writer%init()
call writer%write_geometry_ugrid(nodes, connectivity)
call writer%write_point_data(pressure, 'Pressure')
call writer%write_point_data(velocity, 'Velocity')
if (rank == 0) call writer%write_fragment()
call writer%close()
```

`num_points` と `num_cells` は各 rank が所有する要素数です。ghost 要素は含めません。connectivity は呼び出し側でグローバル 0-origin node ID に変換して渡します。`init`、HDF5 write、`close` は全 rank が同じ順序で呼び、`write_fragment` は rank 0 のみが呼びます。

## PolyData

```fortran
writer%output_type = 'PolyData'
writer%num_points = num_points
writer%num_cells = 0
call writer%init()
call writer%write_geometry_polydata(nodes)
call writer%write_point_data(pressure, 'Pressure')
if (rank == 0) call writer%write_fragment()
call writer%close()
```

同じ `h5_filepath` に先に UnstructuredGrid、次に PolyData を書くと、それぞれ `/ugrid` と `/polydata` group として保存されます。

## 現在の保存形式

```text
/ugrid/geometry/nodes
/ugrid/geometry/connectivity
/ugrid/point_data/<field-name>
/ugrid/cell_data/<field-name>
/polydata/geometry/nodes
/polydata/point_data/<field-name>
```

Fortran の `data(ncomp, nlocal)` は、HDF5 上では `[global_n, ncomp]`、XDMF の `Dimensions` も `"global_n ncomp"` になります。現在は呼び出しごとに固定サイズ dataset を作成し、従来の XDMF fragment 形式を維持しています。

## 将来の unlimited dataset 化

時系列 `misc` データを単一 dataset へ追記する設計は、`H5S_UNLIMITED`、chunk、hyperslab extend を使う別の保存方式として実装する予定です。今回の fypp 化ではその変更を先取りせず、現在のファイル構造と fragment 出力を維持しています。
