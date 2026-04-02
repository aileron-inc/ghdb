# ghdb

Sync GitHub repository files into SQLite via ActiveRecord.

ghdb は GitHub リポジトリのファイルを SQLite データベースに同期する Ruby gem です。
Markdown ファイルの frontmatter をパースして保存し、Rails アプリから ActiveRecord モデルとして参照できます。
[Litestream](https://litestream.io/) と [Tigris](https://www.tigrisdata.com/) を使って SQLite を S3 互換ストレージにレプリケーションします。

## Architecture

```
GitHub Repository
  │
  │ push / merge
  ▼
GitHub Actions
  ├── ghdb build   # ファイル → SQLite
  └── ghdb push    # SQLite → Tigris (via Litestream)
        │
        ▼
  Tigris (S3-compatible)
        │
        │ Litestream restore (on app boot)
        ▼
  Rails App
  └── Ghdb::Repository / Ghdb::BlobEntry (ActiveRecord)
```

## Requirements

- Ruby >= 3.2
- [litestream](https://litestream.io/install/) コマンドがインストール済みであること

## Installation

```bash
gem install ghdb
```

## Environment Variables

| 変数 | 必須 | 説明 |
|------|------|------|
| `GHDB_ACCESS_KEY_ID` | ✅ | Tigris アクセスキー |
| `GHDB_SECRET_ACCESS_KEY` | ✅ | Tigris シークレットキー |
| `GHDB_BUCKET` | ✅ | Tigris バケット名 |
| `GHDB_ENDPOINT` | — | S3 エンドポイント（デフォルト: `fly.storage.tigris.dev`）|
| `GHDB_DB_PATH` | — | SQLite ファイルパス（デフォルト: `.ghdb/ghdb.sqlite`）|

## Usage

### 1. 初期化

litestream の存在確認・環境変数チェックを行い、Tigris に空の SQLite を作成します。

```bash
ghdb init
```

### 2. リポジトリ登録

`.ghdb/config.yml` を生成し、リポジトリをデータベースに登録します。

```bash
ghdb new --repo OWNER/NAME [--branch BRANCH]
```

### 3. ビルド

リポジトリのファイルを SQLite に取り込みます。
初回は全件、2回目以降は `git diff` で変更ファイルのみ処理します。

```bash
ghdb build
```

### 4. プッシュ

SQLite を Tigris にレプリケーションします。

```bash
ghdb push [--replica REPLICA_URL]
```

`--replica` を省略した場合は `GHDB_BUCKET` / `GHDB_ENDPOINT` から自動構築します。

### 5. 確認

```bash
ghdb info
```

```
db:      .ghdb/ghdb.sqlite (2097152 bytes)
replica: s3://my-bucket?endpoint=fly.storage.tigris.dev&region=auto
console: https://console.storage.dev/buckets/my-bucket/objects

owner/repo
  branch:    main
  entries:   1234
  synced_at: 2026-04-02 12:00:00
```

## GitHub Actions

```yaml
name: Sync to SQLite

on:
  push:
    branches:
      - main

jobs:
  sync:
    runs-on: ubuntu-latest
    env:
      GHDB_ACCESS_KEY_ID: ${{ secrets.GHDB_ACCESS_KEY_ID }}
      GHDB_SECRET_ACCESS_KEY: ${{ secrets.GHDB_SECRET_ACCESS_KEY }}
      GHDB_BUCKET: ${{ vars.GHDB_BUCKET }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"

      - name: Install ghdb
        run: gem install ghdb

      - name: Install litestream
        run: |
          curl -fsSL https://github.com/benbjohnson/litestream/releases/latest/download/litestream-linux-amd64.tar.gz \
            | tar -xz -C /usr/local/bin

      - name: Build
        run: ghdb build

      - name: Push
        run: ghdb push
```

## ActiveRecord Models

```ruby
# リポジトリ一覧
Ghdb::Repository.all

# ファイル検索
repo = Ghdb::Repository.find_by(owner: "my-org", name: "my-repo")
repo.blob_entries.where("path LIKE ?", "content/posts/%")

# frontmatter へのアクセス
entry = Ghdb::BlobEntry.first
entry.frontmatter["title"]
entry.frontmatter["date"]
entry.content  # Markdown 本文（frontmatter 除去済み）
```

## Rails での利用

`database.yml` で SQLite を指定し、Litestream で restore した DB を参照します。

```yaml
# config/database.yml
production:
  adapter: sqlite3
  database: /data/ghdb.sqlite
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aileron-inc/ghdb.
