# Aozorasearch ライブラリアップデート設計

## 概要
- 目的は、Aozorasearch の依存ライブラリを現行ローカル環境で更新できる状態へ寄せ、ローカルで再現可能な検証線を追加し、新しい VPS へ移行する前提条件を明確化すること。
- 既存リポジトリは Ruby/Bundler 構成で、`Gemfile.lock` は `BUNDLED WITH 1.17.2` の古い状態に留まっている。
- リポジトリ内に `test/` や `spec/` は存在しないため、依存更新と同時に最小限の自動テストを追加する。

## 目標
- 現行 Ruby 3.2 系で `bundle install` と `bundle update` を実行できるようにする。
- 主要 gem の更新後に、CLI と Web アプリの基本動作をローカルで確認できるようにする。
- 将来の依存更新や VPS 移行でも再利用できる、最小限の自動テストと手動確認手順を持つ状態にする。
- 新しい VPS に必要なランタイム、外部依存、環境変数を棚卸しする。

## 非目標
- 新しい VPS への本番デプロイ自体は今回の対象外とする。
- UI や検索ロジックの仕様変更は行わない。
- 大規模なリファクタリングや、更新対象と無関係なコード整理は行わない。

## 現状整理
- 依存定義は [`aozorasearch.gemspec`](../../aozorasearch.gemspec) に集約されている。
- CLI エントリは [`lib/aozorasearch/command.rb`](../../lib/aozorasearch/command.rb) にあり、`version` / `load` / `search` / `start` を提供している。
- Web アプリは [`lib/aozorasearch/web/app.rb`](../../lib/aozorasearch/web/app.rb) にあり、Sinatra ベースでトップページ、検索、類似文書、ブックマーク画面を提供している。
- 外部依存として Groonga 系 (`rroonga`, `racknga`) があり、ネイティブライブラリや OS パッケージの影響を受ける。

## 更新方針
### 1. Bundler / lockfile の正常化
- まず Bundler 2 系で `Gemfile.lock` を扱える状態に寄せる。
- 更新は `aozorasearch.gemspec` の依存を基準に行い、lockfile の更新は現行 Ruby 環境で再生成する。
- `bundle` 実行環境が不足している場合は、Bundler を導入してから依存更新へ進む。

### 2. gem の段階更新
- 先行対象は純 Ruby かつアプリ互換の影響を局所化しやすい gem とする。
  - `sinatra`
  - `sinatra-contrib`
  - `rack`
  - `nokogiri`
  - `kaminari`
  - `haml`
  - `launchy`
  - `thor`
- `rroonga` と `racknga` は Groonga 本体の互換性確認が必要なため、周辺 gem の更新と切り分けて扱う。
- 破壊的変更が出た場合は、アプリコードを最小限修正して既存の CLI / Web の振る舞いを維持する。

## 検証設計
### 自動テスト
- テストフレームワークは Minitest を採用する。ActiveSupport の依存として既に導入済みで、追加コストが低い。
- HTTP レイヤのテストには `rack-test` を開発依存として追加する。
- 追加する最小テストは以下とする。
  - CLI の `version` がバージョン文字列を返すこと。
  - Web の `/` が 200 を返すこと。
  - Web の `/search` が検索処理をスタブした状態で 200 を返すこと。
  - 必要に応じて `/search.json` の JSON 応答を確認すること。
- Groonga に強く依存する経路はスタブで切り離し、CI やローカルで再現しやすいテストを優先する。

### 手動スモーク確認
- `bundle install`
- 追加した自動テスト一式
- `bundle exec ruby -I lib bin/aozorasearch version`
- `bundle exec ruby -I lib bin/aozorasearch start --silent`
- 起動後のトップページ表示、および代表的な検索導線確認

## VPS 移行前の事前確認
- Ruby の必要バージョン
- Bundler の必要バージョン
- Groonga / Rroonga / Racknga に必要な OS パッケージ
- `AOZORASEARCH_HOME` と `AOZORASEARCH_SUB_URL` の設定要件
- データ配置先と永続化方針

## 受け入れ条件
- 依存更新後に `bundle install` が成功する。
- 追加した自動テストが通る。
- CLI の `version` と Web の基本起動確認が通る。
- 更新内容と検証手順がドキュメント化され、新VPSの事前確認項目が分かる。

## 採用した前提
- 更新対象は「最小限のみ」とし、全面的な最新化は今回行わない。
- ローカル検証は起動確認だけでなく、将来用の最小テスト追加まで含める。
- 新VPS向けには、実デプロイではなく事前条件の棚卸しまでを今回の範囲とする。
