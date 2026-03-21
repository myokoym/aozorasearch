# awesome-codex-subagents からの候補整理

## 背景
- 対象リポジトリは Ruby gem 形式で、Thor CLI と Sinatra Web アプリを同居させている。
- 検索基盤は Groonga / Rroonga で、Web 側は Haml と Kaminari を使っている。
- テストは Minitest と rack-test が中心で、最近は依存互換、VPS デプロイ、運用ドキュメント整備の論点がある。

## 選定基準
- このリポジトリで実際に呼び出す場面を想像しやすいこと。
- Rails / React / Kubernetes のような不一致な前提を持ち込みにくいこと。
- 小さな Ruby アプリでも過剰設計になりにくく、局所的に使えること。
- 既存の開発プロセス（コード変更、テスト、レビュー、運用ドキュメント）と噛み合うこと。

## 常設導入対象

- `api-designer`
- `backend-developer`
- `code-mapper`
- `frontend-developer`
- `fullstack-developer`
- `ui-designer`
- `ui-fixer`
- `database-administrator`
- `deployment-engineer`
- `devops-engineer`
- `security-engineer`
- `sre-engineer`
- `accessibility-tester`
- `architect-reviewer`
- `browser-debugger`
- `code-reviewer`
- `debugger`
- `error-detective`
- `performance-engineer`
- `qa-expert`
- `reviewer`
- `security-auditor`
- `test-automator`
- `build-engineer`
- `cli-developer`
- `dependency-manager`
- `documentation-engineer`
- `dx-optimizer`
- `git-workflow-manager`
- `legacy-modernizer`
- `refactoring-specialist`
- `tooling-engineer`
- `docs-researcher`
- `search-specialist`

## 特に頻度が高い候補

### 1. `code-mapper`
- 用途: 変更前に `/search`、CLI、Groonga ローダーの経路を短時間で把握したいとき。
- 合う理由: このリポジトリは `lib/aozorasearch/command.rb`、`lib/aozorasearch/web/app.rb`、検索/DB 層へ責務が分かれており、変更前の経路確認が有効。
- 想定場面: 不具合修正前の影響範囲確認、サブ URL 対応のような経路追跡、Groonga 依存コードの入口確認。

### 2. `reviewer`
- 用途: 変更後の PR 風レビューを correctness / regression / missing tests 観点で回すとき。
- 合う理由: このプロジェクトは既存挙動維持が重要で、軽微な依存更新や Web 表示修正でも回帰確認が必要。
- 想定場面: ページング、起動経路、デプロイ関連変更のレビュー。

### 3. `debugger`
- 用途: failing test、起動失敗、環境差分起因の不具合の切り分け。
- 合う理由: Sinatra 起動、Gem 互換、Groonga 依存は「再現条件の特定」が先に要る場面が多い。
- 想定場面: `bundle exec rake test` の失敗、`start` / `load` コマンド不具合、開発環境だけ壊れる症状。

### 4. `dependency-manager`
- 用途: Gem 更新、pin、互換性調査、lockfile 変更の整理。
- 合う理由: 現状でも `actionview` や `minitest` に互換性理由の pin があり、依存判断の頻度が高い。
- 想定場面: Sinatra / Kaminari / Rack 系の更新、脆弱性対応、Bundler 解決失敗の整理。

### 5. `cli-developer`
- 用途: Thor CLI の UX 改善、引数や環境変数の扱い整理。
- 合う理由: `load` `search` `start` `version` が明確な運用面を持っており、Web 専用サブエージェントより適合する。
- 想定場面: `start --silent` のようなオプション追加、終了コードや help 文改善、CLI 回帰修正。

### 6. `deployment-engineer`
- 用途: VPS デプロイ、ロールバック、運用手順の安全性確認。
- 合う理由: このリポジトリではデプロイ runbook 整備が進んでおり、アプリコードより運用手順の正しさがボトルネックになりやすい。
- 想定場面: デプロイ手順更新、ロールバック検討、リリースフロー整理。

## 条件付き候補

### 7. `documentation-engineer`
- 合う場面: README や runbook を「実コードと一致しているか」で詰めたいとき。
- 留意点: 実装そのものより文書保守に寄るため、常用よりは docs 更新時の専任向け。

### 8. `backend-developer`
- 合う場面: `/search.json` や検索条件処理など、Web/CLI の挙動を実際に変えるとき。
- 留意点: 認可やトランザクション前提の重い文脈も含むので、この小規模アプリでは少し大きめ。汎用実装役としては使える。

### 9. `performance-engineer`
- 合う場面: 検索遅延、Groonga クエリ、ページングのボトルネック調査。
- 留意点: 普段は出番が少ない。性能問題が顕在化したときだけ投入するのがよい。

### 10. `security-auditor`
- 合う場面: 公開 Web、入力処理、デプロイ設定をまとめて棚卸ししたいとき。
- 留意点: このプロジェクトの主戦場ではあるが、常時呼ぶには重い。リリース前監査向け。

### 11. `legacy-modernizer`
- 合う場面: 古い依存や設計を段階移行する計画を作るとき。
- 留意点: 今すぐの実装作業より、中長期の modernization 議論向け。

## 初回導入では保留にしたもの
- `frontend-developer` / `ui-designer` / `ui-fixer`: Haml ベースの UI 改修、見た目崩れ、検索画面の改善では十分に使い道がある。ただし現状の保守対象は依存互換、CLI、デプロイの比重が高いため、初回セットでは後順位にした。
- `database-administrator`: Groonga のバックアップ、復旧、容量、権限の棚卸しでは補助的に使える。ただし説明の主戦場が一般的な RDBMS 運用寄りで、このリポジトリへの適合度はやや落ちる。
- `docs-researcher`: 公式ドキュメントで挙動確認が要る依存更新や運用判断には有効。ただし常設サブエージェントとしてより、必要時にスポットで使う想定。

## 現時点では非推奨
- `rails-expert`: Sinatra 中心の構成に対して前提がずれやすく、誤誘導のほうが利益を上回りやすい。

## 補足
- ユーザー方針に合わせ、今回は「少しでも使いそうならローカルの `.codex/agents/` に常設する」を採用する。
- 置いてある agent 数より、実際に spawn する数と書き込み競合のほうが実運用コストになりやすい。
- そのため、導入対象は広めに確保しつつ、実際の利用時に担当境界を狭く切る運用がよい。
