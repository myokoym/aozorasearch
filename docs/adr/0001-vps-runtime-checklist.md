# VPS Runtime Checklist

## Status
Proposed

## Context
新しい VPS へ移行する前に、ローカルで Ruby 3.2 系と Groonga 系依存で動作確認できる状態を揃える必要がある。

## Decision
- Ruby 3.2 系を前提にする
- Bundler 2.4 系で `vendor/bundle` を使う
- Groonga は OS package で導入する
- `webrick` を Ruby 3 系の起動用 handler として gem で導入する

## Consequences
- Positive: ローカルと VPS で依存の揺れを減らせる
- Negative: VPS 初期セットアップで OS package の導入が必要

## References
- `.codex/research/20260320041434-library-upgrade-design.md`
- `.codex/plans/20260320041434-library-upgrade.md`
