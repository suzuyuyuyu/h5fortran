# Examples

用途ごとに独立した最小例を置く。

| ディレクトリ | 内容 | 実行ファイル |
|---|---|---|
| `serial/` | Serial手続きAPI | `example_serial` |
| `serial-oop/` | Serial OOP API | `example_serial_oop` |
| `parallel/` | Parallel手続きAPI | `example_parallel` |
| `parallel-oop/` | Parallel OOP API | `example_parallel_oop` |
| [`serial-viz/`](serial-viz/README.md) | 逐次可視化HDF5とXDMF生成（`t_hdf5_writer`） | `example_serial_viz` |
| [`parallel-viz/`](parallel-viz/README.md) | 並列可視化HDF5とXDMF生成（`t_phdf5_writer`） | `example_parallel_viz` |

リポジトリ全体から、すべてをまとめてコンパイルする。

```sh
cmake -S . -B build
cmake --build build --target examples
```

`example/` を独立したCMake projectとしてconfigureすることもできる。この場合も
同じリポジトリのh5fortranライブラリを自動的に一緒にビルドする。

```sh
cmake -S example -B example/_build
cmake --build example/_build --target examples
```

非標準のcompilerやHDF5を使う場合は、root projectと同様に
`-DCMAKE_Fortran_COMPILER=...` と `-DHDF5_ROOT=...` を指定する。

Serial例:

```sh
build/example/example_serial
build/example/example_serial_oop
```

standalone configureでは `example/_build/example/` 以下に生成される。

Parallel例（クラスタではジョブスクリプト内で実行。ログインノードでは実行しない）:

```sh
mpiexec -n 2 build/example/example_parallel
mpiexec -n 2 build/example/example_parallel_oop
```

逐次可視化例は次のコマンドで1プロセスのHDF5出力から後処理まで実行する。

```sh
example/serial-viz/generate.sh build
```

並列可視化例は `example/parallel-viz/generate.sh build` をジョブスクリプトから
実行する。両例とも四面体meshと粒子群を同じfield名で5時刻分出力する。
Serial例は常にビルドされ、Parallel例は
`H5FORTRAN_ENABLE_PARALLEL=ON` のときにビルドされる。
