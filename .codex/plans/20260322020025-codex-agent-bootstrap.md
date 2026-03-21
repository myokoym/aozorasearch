# Codex Agent Bootstrap 実装 plan

## 要約
- 今回の本丸は、新しく clone した環境でも upstream の subagent カタログを取得し、選定済み agent を `.codex/agents/` に同期できる再実行可能な仕組みを入れること。
- 導入対象は「少しでも使いそうなものは全部入れる」方針で固定し、初回導入の絞り込みはしない。
- `tmp/awesome-codex-subagents` 依存の手作業をやめ、スクリプトで clone / pull / copy を一貫実行できるようにする。
- スクリプトは upstream URL、cache dir、destination dir を上書き可能にして、ローカル fixture で自動テストできるようにする。
- README には clone 後の実行手順だけを短く追記し、詳細な導入対象や理由は research メモへ残す。

## 完了条件
- `scripts/setup-codex-agents.sh` が新規 clone 環境を想定して upstream を取得し、対象 `.toml` を `.codex/agents/` へ同期できる。
- スクリプトの挙動を検証する自動テストが追加され、fail-first から green まで確認できる。
- `.codex/agents/` に現在の「十分導入に値する」agent 群が実際に配置される。
- README に clone 後のセットアップ手順が反映される。
- `bundle exec rake test` が pass する。

## 主要マイルストーン
- マイルストーン1: 導入対象 agent 一覧とスクリプト仕様を確定する。
- マイルストーン2: スクリプト用テストを追加し、未実装状態で失敗させる。
- マイルストーン3: スクリプト本体と補助ファイルを実装し、`.codex/agents/` を同期する。
- マイルストーン4: README / research を更新し、全テストを通す。

## 詳細タスク

### 1. 導入対象の確定
- `awesome-codex-subagents` から、このリポジトリで少しでも使いそうな agent を列挙する。
- 明らかに前提がずれるものだけ除外し、対象一覧をスクリプトの管理対象として固定する。
- 管理対象はスクリプト内で一元管理し、将来の追加・削除が差分で追えるようにする。

### 2. テスト設計
- `test/` 配下にスクリプト専用テストを追加する。
- テストでは local fixture として `tmp/awesome-codex-subagents` を source に指定し、network に依存せず実行できるようにする。
- 期待値:
  - 対象 agent の `.toml` が destination に作成されること。
  - 保留ではなく今回の常設対象に含めた agent もコピーされること。
  - 管理対象 manifest が生成・更新されること。
  - 再実行しても破綻しないこと。

### 3. スクリプト実装
- `scripts/setup-codex-agents.sh` を追加する。
- 役割:
  - upstream repo の clone または pull
  - `.codex/agents/` の作成
  - 対象 `.toml` の copy
  - 以前の管理対象から外れた `.toml` のみ安全に削除
  - 現在の管理対象 manifest の更新
- source URL / cache dir / destination dir は環境変数で上書き可能にする。
- 新規 clone 時の標準経路として、repo 内の cache dir を使う。

### 4. ドキュメント更新
- README に clone 後の実行手順を追加する。
- research メモの agent 選定結果を「初回導入の絞り込み」前提から、「常設導入セット」前提へ更新する。

### 5. 検証
- 追加したテストを個別実行して red → green を確認する。
- その後 `bundle exec rake test` を実行して既存テストも含めて pass を確認する。

## 中間段階の注意
- テストだけ追加して失敗している段階では完了ではない。
- スクリプトだけ実装して README と `.codex/agents/` 同期結果が欠けていても完了ではない。
