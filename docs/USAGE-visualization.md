 Tohoku University, Keiriki
------------------------------------------------------------------------------

 MODULE: h5fort_parallel_hdf5_xdmf

> @author
> Yuta Suzuki

 DESCRIPTION:
>  Output HDF5 files and XDMF fragments for parallel visualization with ParaView.

 REVISION HISTORY:
------------------------------------------------------------------------------
 module_phdf5.F90 - Parallel HDF5 ライタ (MPI-IO / Collective I/O)

 既存の module_hdf5 / t_hdf5_writer と同じ呼び出し界面を保ちつつ、
 全ランクが 1 つの共有 HDF5 ファイルへ MPI-IO で書き込む。

 HDF5 ファイル構造 (タイムステップごとに 1 ファイル、全ランク共有):
   ファイル名パターン:
     ts{ts:04d}.h5  (/ugrid + /polydata 両グループを格納)

   ts{ts:04d}.h5:
   /ugrid/
     geometry/
       nodes        [total_np][3]   float64   (全ランク連結)
       connectivity [total_nc][8]   int64     (グローバルノード番号, offset_points 加算済み)
     point_data/
       <name>       [total_np]      or [total_np][ncomp]
     cell_data/
       <name>       [total_nc]
   /polydata/
     geometry/
       nodes        [total_np][3]   float64
     point_data/
       <name>       [total_np]      or [total_np][ncomp]

 connectivity について:
   呼び出し側がグローバル 0-indexed 番号に変換してから渡す。
   (ローカル -> グローバルの変換は sample_build_comm_info 等の呼び出し側で行う)
   XDMF がグローバル dataset を直接参照するため、グローバルノード番号で格納する。

 次元の注意 (module_hdf5 と同一):
   Fortran 配列 data(ncomp, np) (列優先) を HDF5 dims=[ncomp, np] で渡すと
   HDF5 ファイルには C 行優先の [np][ncomp] として格納される。
   XDMF の Dimensions 属性も C 順: "np ncomp"

 使い方:

   ug%h5_filepath   = 'result/phdf5/ts0000.h5'
   ug%output_type = 'UnstructuredGrid'
   ug%num_points  = np
   ug%num_cells   = nc
   ug%comm        = MPI_COMM_WORLD     ! integer MPI コミュニケータ
   ug%me          = me_proc
   ug%nprocs      = nprocs
   call ug%init()     ! MPI_Allgather + ファイル新規作成（全ランク集合的）
   call ug%write_geometry_ugrid(nodes, connectivity)
   call ug%write_point_data(pressure, 'Pressure')
   call ug%close()

   ! PolyData は同じファイルに追記（init が既存ファイルを RDWR で再オープン）
   pd%h5_filepath   = 'result/phdf5/ts0000.h5'
   pd%output_type = 'PolyData'
   ...
   call pd%init()
   call pd%write_geometry_polydata(nodes)
   call pd%close()


------------------------------------------------------------------------------

 write_fragment でグローバル mesh を直接参照する。
 HyperSlab / rank Grid は使わない。
 ParaView XDMF3 Reader T で読み込み可能。

 断片ファイル名:
   metadata/ts{ts:04d}_{output_type}_phdf5.xdmf.part

 断片ファイル構造 (ugrid 例):
   <Topology TopologyType="Hexahedron" NumberOfElements="1000">
     <DataItem Format="HDF" NumberType="Int" Precision="8" Dimensions="1000 8">
       ../phdf5/ts0000.h5:/ugrid/geometry/connectivity
     </DataItem>
   </Topology>
   <Geometry GeometryType="XYZ">
     <DataItem Format="HDF" NumberType="Float" Precision="8" Dimensions="1694 3">
       ../phdf5/ts0000.h5:/ugrid/geometry/nodes
     </DataItem>
   </Geometry>
   <Attribute Name="Pressure" AttributeType="Scalar" Center="Node">
     <DataItem Format="HDF" NumberType="Float" Precision="8" Dimensions="1694">
       ../phdf5/ts0000.h5:/ugrid/point_data/Pressure
     </DataItem>
   </Attribute>
   ...

 output_xdmf がこの断片を <Grid GridType="Uniform"> でラップし、
 Temporal Collection を構成する。

 最終 XDMF 構造:
   Temporal Collection
    ├ Uniform Grid (ts0000) ← time + fragment content
    ├ Uniform Grid (ts0001)
    └ ...

------------------------------------------------------------------------------
