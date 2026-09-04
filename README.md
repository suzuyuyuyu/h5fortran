<h1 align="center">h5fortran</h1>

Serial / Parallel HDF5 を Fortran から簡潔に扱うためのラッパーです。手続き API と、ファイル ID・エラー状態を保持する OOP API を提供します。

## 必要なもの

- Fortran 2008 対応コンパイラ
- HDF5（Fortran / HL component）
- Parallel API を使う場合は Parallel HDF5 と MPI Fortran
- 生成ソースを更新する場合は fypp 3.2

## Build

HDF5 は通常の `find_package(HDF5)` で探索します。非標準 prefix は `HDF5_ROOT` で指定してください。

```sh
cmake -S . -B build -DHDF5_ROOT=/path/to/hdf5
cmake --build build
ctest --test-dir build --output-on-failure
cmake --install build --prefix "$HOME/.local"
```

Serial / Parallel は個別に選択できます（既定は両方 `ON`）。

```sh
# Serial のみ。MPI と Parallel HDF5 は不要
cmake -S . -B build-serial \
  -DH5FORTRAN_ENABLE_SERIAL=ON \
  -DH5FORTRAN_ENABLE_PARALLEL=OFF
```

インストール後は次の target を利用します。

```cmake
find_package(h5fortran CONFIG REQUIRED)
target_link_libraries(my_program PRIVATE h5fortran::h5fortran)
```

手続きAPI、OOP API、可視化の利用例は [`example/`](example/) に用途別で配置して
います。すべてまとめてビルドできます。

```sh
cmake --build build --target examples
```

APIの詳細は [docs/USAGE.md](docs/USAGE.md) を参照してください。

可視化用HDF5のレイアウトと、HDF5時系列からXDMF3を生成するPythonツールは
[docs/USAGE-visualization.md](docs/USAGE-visualization.md) と独立リポジトリ
[`h5xdmf`](https://github.com/suzuyuyuyu/h5xdmf) を参照してください。
snapshot、manifest、XDMFの責務は
[docs/POSTPROCESS.md](docs/POSTPROCESS.md) にまとめています。
完成した出力構成を生成する例は
[`example/visualization`](example/visualization/) にあります。

## fypp 生成

型・rank 別の Fortran ソースは `src/fypp/` を正とします。

```sh
src/fypp/generate_fypp.sh
src/fypp/generate_fypp.sh --check
```

`FYPP=/path/to/fypp` で実行ファイルを上書きできます。CI 相当の同期確認は CTest の `generated_sources` でも実行されます。
