# TODO
これから取り組みたいことについて記録する。

## Common
- [x] ファイル名の桁数は固定しない。辞書順が時系列順になるよう、同じrunでは
  `seqNNNNNN.h5` のようにゼロ埋め桁数を統一する。

## h5fortran
- [?] 任意の診断量を1つのdatasetへ時系列追記する汎用UNLIMITED API
    - 可視化metadataのためには実装しない。snapshot HDF5を正本とし、Pythonが
      `metadata.h5` を構築する現在の方式を維持する。
    - `num_particles` は `metadata.h5` のmeshごとのentity数から取得できる。
    - 可視化以外の診断量を単一HDF5へ蓄積する明確な要求が生じた場合だけ検討する。
- [?] serial のなかに `__partition__` と拡張可能データセット `data` のセットを出力し、parallel に読み込めるようなデータグループを書き出すためのサブルーチンを作成する

## h5c/h5cpp 設計レビューで見つかった h5fortran 側の課題

`h5c` の設計検討（2026-08-18）で HDF5 C API と比較した際に気づいた点。
`h5fortran` の現在の動作は仕様どおりであり、以下はいずれも改善候補である。

- [x] Parallel write のランク発散する早期 return
    - `src/parallel/h5fort_parallel_write.F90` の `begin_parallel_write` は
      `MPI_Comm_rank` / `MPI_Allgather` / `h5gcreate_f` / `h5pcreate_f` の
      失敗時にそのランクだけ return する。一部ランクだけが失敗した場合、
      残りのランクは collective な `h5dwrite_f` へ進むためデッドロックしうる。
    - 次元一致の検証は `MPI_Allreduce` の MIN/MAX で全ランクに集約されており
      問題ない。対処が必要なのは HDF5・MPI 自体の失敗パスのみ。
    - `hdferr` を `MPI_Allreduce(MPI_MAX)` などで集約し、全ランクが同一の
      判断で抜けるようにするのが素直な対処。
- [x] ゼロサイズ選択で `H5Sselect_none` 相当を使っていない
    - ローカル長 0 のランクも長さ 0 の hyperslab 選択のまま collective 呼び出しへ
      入る。現状のテスト（`/zero`）は通っているが、長さ 0 の hyperslab 選択は
      HDF5 のバージョンや MPI-IO 実装によって扱いが揺れうる箇所である。
    - `h5sselect_none_f` を明示的に呼ぶ方が意味論が曖昧にならない。
- [x] Parallel の communicator が `MPI_COMM_WORLD` 決め打ち
    - `src/parallel/h5fort_parallel.F90` の `h5pset_fapl_mpio_f` と、
      `h5fort_parallel_write.F90` の集団通信がすべて `MPI_COMM_WORLD` を使う。
      サブコミュニケータでの並列 I/O（I/O 専用ランク群、複数ケースの同時実行）
      ができない。可視化 writer は `self%comm` を保持しており、こちらは対応済み。
    - `MPI_Info` も `MPI_INFO_NULL` 固定で、ROMIO ヒントを渡せない。
- [x] 転送モードが collective 固定
    - `h5pset_dxpl_mpio_f(..., H5FD_MPIO_COLLECTIVE_F)` が決め打ちで、
      independent を選べない。既定は collective のままでよいが、
      ランクごとの負荷が極端に偏る場合に選択肢がないのは制約になる。
- [x] dataset の rank・shape を問い合わせる公開 API がない
    - `get_dataset_info` は `h5fort_serial_write` の内部手続きに留まる。
      Fortran では allocatable read が形状を吸収するため実害は小さいが、
      「読む前に形状を知りたい」用途（バッファの事前確保、分岐処理）には
      対応できない。
- [x] 汎用 API の対応型が限定的
    - 汎用 read/write は real64 / real32 / int32 / logical / character(scalar)
      のみで、`integer(int64)` がない。real128 と int8/int16/int64 は
      可視化 writer だけが対応している。
    - `h5c` では int64 を含める方針のため、`h5c` が書いた int64 dataset は
      現状の `h5fortran` では読めない。実需が出た時点で検討する。
- [?] Parallel の文字列 I/O が未実装
    - SPEC.md に既知事項として記載済み。`h5c` でも当面は同様とする。
- `logical` の保存が int32 で、1 要素あたり 4 バイトを使っている
    - `H5T_STD_I8LE` にすれば 1 バイトで済み、ファイルサイズと I/O 量が 1/4 になる。
      さらに int8 を基底とする enum（`FALSE=0`, `TRUE=1`）にすると `h5dump` で
      `TRUE`/`FALSE` と表示され、h5py が `np.bool_` として読む。これは h5py が
      numpy の bool を保存するときの表現であり、HDF5 における boolean の慣習である。
    - 書き込み側は既に `integer(int32)` の一時配列を確保して `merge()` で詰め替えて
      いるため、int8 にしても払うコストは変わらない。int32 であることの利点はない。
    - 読み込み側（`h5fort_read_lgc_*`）は rank しか検査せず `H5T_NATIVE_INTEGER` で
      読むため、HDF5 の自動変換により int8 や enum の dataset もそのまま読める
      （C の往復テストで確認済み）。したがって reader を変更せずに writer だけ
      int8 化しても、既存ファイルとの後方互換は保たれる。
    - `h5c` は int8 基底の enum を採用する方針のため、`h5c` が書いた logical を
      `h5fortran` は読めるが、`h5fortran` が書いた int32 の logical を `h5c` が読むと
      HDF5 の I32→I8 変換が入る（動作上の問題はない）。
- [x] Tensor6 の成分順序が文書化されていない
    - `write_field_metadata_` は `ncomp` から `Scalar|Vector|Tensor6|Tensor` を決めるが、
      `ncomp=6` のときの成分の並び順が文書化されていない。
    - `h5xdmf`は列を並べ替えずParaView/VTKへ渡すため、XDMF3仕様文の
      `XX, XY, XZ, YY, YZ, ZZ`ではなく、ParaView/VTKが期待する
      `XX, YY, ZZ, XY, YZ, XZ`に合わせる必要があることが判明した。`SPEC.md`を訂正済み。
