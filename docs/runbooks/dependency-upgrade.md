# 依存更新ランブック

## 目的

Aozorasearch の依存ライブラリ更新を、毎回同じ基準で再実行できるようにする。

## 対象

- gem の更新
- lockfile の更新
- ローカル起動確認
- 脆弱性確認
- warning の整理

## 成功の定義

依存更新は、次をすべて満たしたときに成功とする。

- `bundle install` が通る
- `bundle exec rake test` が PASS する
- `bundle exec ruby -I lib bin/aozorasearch version` が成功する
- `bundle exec ruby -I lib bin/aozorasearch start --silent` で起動し、`curl -I --max-time 5 http://127.0.0.1:4567/` が `200 OK` を返す
- `bundle exec bundler-audit check --update` が成功する
- `bundle exec bundler-audit check` が `No vulnerabilities found` を返す
- 新しく増えた warning を放置していない

## Warning の扱い

### `bundler-audit` の指摘

- `bundler-audit` が脆弱性を報告した場合、そのまま完了扱いにしない
- 依存元を含めて更新し、`No vulnerabilities found` になるまで解消する

### 実行時 warning

ここでいう warning は、`bundler-audit` ではなく、`bundle install`、`bundle exec rake test`、`bundle exec ruby ...` の実行中に Ruby や gem が出す警告を指す。

例:
- deprecation warning
- method redefined warning
- assigned but unused variable
- possibly useless use of a variable in void context

扱いは次の通りとする。

- 依存更新で新しく出た warning は、原因を特定して解消する
- すぐに消せない warning を残す場合は、理由、影響、次アクションをコードコメントまたはコミットメッセージに残す
- 理由が説明できない warning は残したまま完了扱いにしない

## 前提条件

- 作業開始前に `git status --short` が空であること
- Ruby 3.2 系と Bundler 2 系が使えること
- Bundler の install 先は `vendor/bundle` を使うこと

```bash
bundle config set path vendor/bundle
```

- Ubuntu 系では少なくとも次の package が入っていること

```bash
sudo apt-get update
sudo apt-get install -y ruby-dev build-essential pkg-config groonga libgroonga-dev groonga-bin
```

## 手順

### 1. 作業ブランチを作る

```bash
git switch -c feature/dependency-upgrade-<date>
```

必要なら worktree を使う。

```bash
git worktree add .worktrees/dependency-upgrade-<date> -b feature/dependency-upgrade-<date> master
```

### 2. 現在の状態を確認する

```bash
git status --short
ruby -v
bundle -v
bundle install
bundle exec rake test
bundle exec ruby -I lib bin/aozorasearch version
bundle exec bundler-audit check --update
bundle exec bundler-audit check
```

### 3. 依存を更新する

更新は 1 回で全部混ぜず、論理単位で進める。

#### 3-1. Web 起動の中核依存

```bash
bundle update sinatra sinatra-contrib rack rack-protection rackup puma webrick
```

#### 3-2. View / Utility 依存

```bash
bundle update thor launchy haml kaminari kaminari-sinatra padrino-helpers padrino-support nokogiri
```

#### 3-3. Groonga 系依存

```bash
bundle update rroonga racknga
```

#### 3-4. 脆弱性対応

`bundler-audit` で出た gem を、依存元ごと更新する。

例:

```bash
bundle update launchy addressable public_suffix
```

### 4. 各バッチ後に確認する

```bash
bundle install
bundle exec rake test
bundle exec ruby -I lib bin/aozorasearch version
bundle exec bundler-audit check
```

Web 起動に影響する更新の後は、次も実行する。

```bash
bundle exec ruby -I lib bin/aozorasearch start --silent &
SERVER_PID=$!
curl -I --max-time 5 http://127.0.0.1:4567/
kill $SERVER_PID
```

### 5. コミットする

次を混ぜない。

- テスト基盤追加
- 主要依存更新
- Groonga 系更新
- 脆弱性対応
- 文書整理

特殊な pin や workaround を入れる場合は、理由をコードコメントまたはコミットメッセージに必ず残す。

## 参照

- `.codex/plans/20260320041434-library-upgrade.md`
- `.codex/research/20260320041434-library-upgrade-design.md`
- `docs/adr/0001-vps-runtime-checklist.md`
