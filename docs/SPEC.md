# h5fortran 仕様

## 公開 API

| API | Serial | Parallel |
|---|---:|---:|
| allocatable read / write | scalar, 1D–4D | scalar, 1D–4D |
| fixed-size read | 1D–4D | 1D–4D |
| `real(real64)` | yes | yes |
| `real(real32)` | yes | yes |
| `integer(int32)` | yes | yes |
| `logical` | yes | yes |
| scalar `character` | yes | no |
| 文字列属性・`units` | write | no |

公開する手続き generic は Serial の `h5fort_swrite` / `h5fort_sread` / `h5fort_sread_fixed` と、Parallel の `h5fort_pwrite` / `h5fort_pread` / `h5fort_pread_fixed` である。対応する OOP type は `t_h5fort_serial` と `t_h5fort_parallel` である。

## ファイル mode

- `H5FORTRAN_FORCE_WRITE = 1`: ファイルを truncate create する。Serial dataset write の optional mode に指定した場合は既存 dataset を置換する。
- `H5FORTRAN_READ_ONLY = 2`: 既存ファイルを read-only で開く。
- mode 省略: 既存ファイルを read-write で開く。

未設定または空の `f_name`、二重 open、二重 close は失敗し、`hdferr` を非ゼロにする。

## エラー契約

公開手続きは成功時に `hdferr = 0`、失敗時に非ゼロを返す。一連の処理で複数の操作が失敗した場合は、最初の非ゼロ値を保持する。後続の resource close や属性書き込みの成功で先行エラーを消してはならない。

allocatable read は dataset の rank を確認してから allocate する。fixed-size read は rank と各次元の長さが一致しない場合に失敗する。

## Parallel 分割

Parallel 配列は最終次元を MPI rank 間の分割方向とする。最終次元の長さは rank ごとに異なってよく、0 も許可する。それ以外の次元は全 rank で一致しなければならず、不一致は HDF5 collective call より前に拒否する。

path `P` の保存形式は次のとおりである。

- `P/data`: 最終次元方向へ連結したデータ
- `P/__count__`: rank ごとのローカル最終次元長
- `P/__offset__`: rank ごとの `data` 内開始位置

`__count__` と `__offset__` の名前は `H5FORT_DSET_COUNT_DNAME` と `H5FORT_DSET_OFFSET_DNAME` で変更できる。

## 生成物

`src/fypp/` の `.fypp` を生成元とし、`src/serial/` と `src/parallel/` の型・rank 展開済みソースは直接編集しない。fypp 3.2 を使用し、`src/fypp/generate_fypp.sh --check` で同期を検証する。

## XDMF visualization writer

`t_phdf5_writer` は従来の公開名と HDF5 group 構造を維持する。geometry は real32/real64/real128、connectivity は int8/int16/int32/int64、point/cell data はこれら7 kindの1D・2Dに対応する。XDMF attribute metadata は dataset write 時に型、precision、成分数から自動登録する。

現在の dataset は固定サイズであり、`misc` の時系列追記に `H5S_UNLIMITED` を用いる将来形式とは別仕様とする。
