# テスト

```sh
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

テスト範囲は次のとおり。

- Serial: real64 scalar と 1D–4D、real32、int32、logical、文字列
- Serial: logical fixed read、属性、units、中間 group、強制上書き
- Serial: 不正 path、rank/shape 不一致、read-only write、未設定ファイル名、二重 open/close
- Parallel（4 rank）: 1D/2D、real32、int32、logical、fixed read、0 要素の rank
- Parallel: 非分割次元不一致の拒否、path/rank エラー、OOP read-only と状態エラー
- XDMF: 全integer/real kindのpoint/cell data、2D vector、geometry/connectivity、fragmentの型・precision
- fypp 生成元と生成済みソースの同期
- install 後の外部 consumer configure/build
- Serial / Parallel example のコンパイル

MPI test は CMake が検出した `MPIEXEC_EXECUTABLE` と `MPIEXEC_NUMPROC_FLAG` を使う。実行環境が socket 作成や process spawn を禁止している場合、Parallel test のみ実行環境側の許可が必要になる。
