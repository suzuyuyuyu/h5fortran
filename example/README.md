# Examples

用途ごとに独立した最小例を置く。

| ディレクトリ | 内容 | 実行ファイル |
|---|---|---|
| `serial/` | Serial手続きAPI | `example_serial` |
| `serial-oop/` | Serial OOP API | `example_serial_oop` |
| `parallel/` | Parallel手続きAPI | `example_parallel` |
| `parallel-oop/` | Parallel OOP API | `example_parallel_oop` |
| `visualization/` | 可視化HDF5とXDMF生成 | `example_visualization` |

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

Parallel例:

```sh
mpiexec -n 2 build/example/example_parallel
mpiexec -n 2 build/example/example_parallel_oop
```

可視化例は次のコマンドでMPI出力からPython後処理まで実行する。

```sh
example/visualization/generate.sh build
```
