# Overview
Parallel/Serial HDF5 の Fortran 用 wrapper です。

# What LLM Agents Should See?
- AGENTS.md (This file)
- README.md
- RULES.md
- docs/*.md

# Format
## Git Commit

Commit messages should be concise and descriptive. Use the following format:
```
<prefix>(<scope>): <overview>
    - <detail>
    - <detail>
```

# docs/
docs は積極的に更新して構いません。
日本語で書いてください。
- SPEC.md: 仕様書
- USAGE.md: 使い方

# logs/
logs/ も同様に更新して構いません。
これはバージョン管理関係のドキュメントを保持します。
バージョンは CMakeLists.txt で v.major.minor.patch のように管理されます。
major update は後方互換性がなくなる更新、minor update は後方互換性があるが機能の追加があった更新、patch は軽微な修正です。
major update, minor update は CHANGELOG.md に記述してください。
patch は v1.md のような major version に紐づけた Markdown で記述してください。
