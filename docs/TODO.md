# TODO
これから取り組みたいことについて記録する。
重要なものから順に [!] -> なにもつけない -> [?] の印を付ける。

## h5fortran
- [?] 任意の診断量を1つのdatasetへ時系列追記する汎用UNLIMITED API
    - 可視化metadataのためには実装しない。snapshot HDF5を正本とし、Pythonが
      `metadata.h5` を構築する現在の方式を維持する。
    - `num_particles` は `metadata.h5` のmeshごとのentity数から取得できる。
    - 可視化以外の診断量を単一HDF5へ蓄積する明確な要求が生じた場合だけ検討する。
- [?] serial のなかに `__partition__` と拡張可能データセット `data` のセットを出力し、parallel に読み込めるようなデータグループを書き出すためのサブルーチンを作成する

## h5xdmf (postprocess)
- HDF5 schemaを明示的に検査する `h5xdmf validate`
- 書き込み途中のsnapshotを除外する完了markerまたは一時名運用
- snapshot削除後にmanifestから存在しないstepを除く `--prune`
- [?] 同一mesh名の複数空間ブロックまたはAMR
    - 実際に必要になった場合、h5xdmf Version 0.2としてmetadata schemaを設計する。

## Both of above
- ファイル名の桁数は固定しない。辞書順が時系列順になるよう、同じrunでは
  `seqNNNNNN.h5` のようにゼロ埋め桁数を統一する。
