# 構造・実装レビューと今後の作業

最終確認日: 2026-07-13

## 現在の構造

- `src/fypp/`: Serial/Parallel API の生成元。型とランクごとの手続きを fypp で展開する。
- `src/serial/`, `src/parallel/`: ビルド対象となる生成済み Fortran ソース。
- `src/h5fort.F90`: Serial/Parallel の公開 API をまとめる facade。
- `test/`: Serial と 4 MPI rank の Parallel に対する最小限の往復テスト。
- `example/`: 利用例。ただし現在の API と一致していない例がある。
- `cmake/`: インストール後に利用する package config。

型・ランクごとの反復実装を fypp に寄せる方針と、低水準の手続き API と OOP API を分ける方針は妥当である。一方、生成手順がリポジトリに存在せず、生成元と生成物の同期を検証する仕組みもないため、現状では安全に変更できない。

## 確認した不具合

### P0: 新規 CMake configure が失敗する

`src/CMakeLists.txt` の install export に次の問題があり、空の build directory では generate step が失敗する。

- `h5fortran_serial`、`h5fortran_parallel`、`h5fortran` の `PUBLIC` include path に source/build directory の絶対パスが入っている。
- 公開依存の `h5fortran_hdf5` が `h5fortranTargets` export set に含まれていない。

既存の `build/` は過去に生成済みであるため、この問題を隠している。`BUILD_INTERFACE` と `INSTALL_INTERFACE` を使い分け、`h5fortran_hdf5` も export するか、HDF5 の imported targets を直接公開依存にする必要がある。インストール後の consumer project で `find_package(h5fortran)` とコンパイルを行うテストも追加する。

### P1: OOP Parallel open が失敗を成功として返す場合がある

`h5fort_parallel_open` は `h5fcreate_f` / `h5fopen_f` の直後に、同じ `self%hdferr` を使って `h5pclose_f` を呼ぶ。ファイル open が失敗しても property list の close が成功すると `self%hdferr` が 0 に上書きされる。

cleanup 用の `err_local` を用意し、最初のエラーを保持する必要がある。同じ問題は Serial/Parallel の `close` にもあり、`h5fclose_f` の結果が `h5close_f` で上書きされる。fypp の生成元を修正する。

### P1: Serial write が close・属性書き込みの失敗を返さない

各 `h5fort_write_*` はデータ書き込み後の `h5dclose_f`、`h5fort_swrite_attr`、`write_units_attr` の結果を `err_local` に受けるだけで、`hdferr` に反映しない。このため、属性の作成に失敗しても呼び出し側には成功と見える。また `attrs` と `units` の両方を指定すると、前者の失敗を後者の成功で上書きする。

全リソース解放処理で「最初の非ゼロ値を保持する」共通規則を採用し、生成元に helper を追加する。

### P1: Parallel read がデータセットの rank を検証しない

`get_data_rank_dims` は rank を返すが、`h5fort_read_*_[2-4]d` は期待 rank と比較せず `dims` を使う。異なる rank のデータを要求した場合、初期値 `1` を次元として誤った配列を確保するか、HDF5 呼び出しまで不整合が持ち越される。Serial read と同様に、確保前に rank を検証して明示的なエラーを返す。

### P1: 生成手順が欠落している

生成済みファイルの先頭は `scripts/generate_fypp.sh` を参照するが、`scripts/` 自体が存在しない。生成元を修正しても成果物へ反映する公式手段がない。

スクリプトを追加し、fypp のバージョンを固定または文書化する。CI では再生成後に `git diff --exit-code` を実行して同期を保証する。

### P2: API・文書・example が一致していない

- `docs/USAGE.md` の OOP 呼び出しは `file_id` と `hdferr` を渡しているが、現在の type-bound procedure は内部の `self%file_id` / `self%hdferr` を使う。
- `example/small-serial.F90` も旧 OOP シグネチャを使っており、CMake の build/test 対象ではない。
- `docs/USAGE.md` は Parallel 保存先を `__data__` と記載するが、実装は `data` を使う。
- `docs/USAGE.md` は logical の固定配列 read を説明していない。生成された下位手続きには存在するが、`h5fort_sread_fixed` / `h5fort_pread_fixed` と OOP generic から公開されていない。

example を CMake target と CTest の compile test に含め、公開 API 一覧を生成元と同じ型・ランク表で管理する。

### P2: CMake が特定環境に強く依存している

- HDF5 の既定 prefix が `$HOME/.local/opt/intel/phdf5` 固定である。
- `H5pubconf.h` を固定 prefix から直接読むため、通常の `find_package(HDF5)` の探索結果とずれる可能性がある。
- MPI launcher の候補にシステム固有の `/opt/system/app/intel/...` が埋め込まれている。
- install target に HDF5 prefix の rpath を公開 link option として固定している。

`find_package(MPI REQUIRED COMPONENTS Fortran)`、`MPI::MPI_Fortran`、`MPIEXEC_EXECUTABLE`、HDF5 imported targets を利用する。Serial-only build を提供する場合は Parallel HDF5 の必須チェックを option の内側へ移す。

## テストで不足している範囲

現在の Serial test は `real64` 2D、Parallel test は `real64` 1D/2D の正常系だけを確認する。少なくとも次を追加する。

1. `real32`、`int32`、`logical`、文字列、scalar、1D から 4D の表形式テスト。
2. 属性、`units`、中間 group 作成、強制上書きの正常系と失敗系。
3. 存在しない path、型不一致、rank/shape 不一致を含むエラー伝播。
4. 0 要素を持つ rank が混在する Parallel I/O。
5. rank ごとに非分割次元が異なる入力を拒否する検証。
6. OOP open/close の二重呼び出し、未設定 `f_name`、read-only open。
7. install 後の外部 consumer build。
8. example のコンパイルと実行。

## 推奨する実装順序

1. P0 の CMake export を直し、clean configure/build/install/consumer test を通す。
2. fypp 再生成スクリプトと同期チェックを追加し、生成元を唯一の編集対象にする。
3. エラー保持用 helper を導入し、open/close/write/read の cleanup を統一する。
4. Parallel read の rank 検証と、全 rank で非分割次元が一致することの検証を追加する。
5. 公開する型・ランクの仕様を `docs/SPEC.md` に確定し、logical fixed read などの欠落を解消する。
6. テスト行列を拡充した後、文書と example を現 API に合わせる。
7. Serial-only / Parallel build option と移植可能な dependency discovery を整備する。

## 今回の検証結果

- 既存 build の Serial CTest: 成功。
- 既存 build の Parallel CTest: 実行環境で MPI launcher が socket を作成できず未検証。
- 空の build directory での CMake configure: 上記 P0 により generate step で失敗。
- `docs/SPEC.md`: 空ファイル。公開 API、保存形式、エラー契約を今後ここに定義する必要がある。
