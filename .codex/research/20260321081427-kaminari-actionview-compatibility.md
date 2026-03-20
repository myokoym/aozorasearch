# kaminari と actionview の互換性問題整理

## 現象

- `bundle exec ruby -I lib bin/aozorasearch start` でトップページ描画時に落ちる
- 例外は `kaminari-sinatra` の `ActionViewTemplateProxy` 初期化から発生する
- 実際のエラーは `ActionView::Base#initialize` の引数不一致

## 根本原因

- `kaminari-sinatra 1.0.1` は `ActionViewTemplateProxy < ActionView::Base` の `initialize` で `super()` を呼ぶ
- `actionview 8.1.2` の `ActionView::Base#initialize` は `lookup_context, assigns, controller` の 3 引数必須
- そのため、`kaminari-sinatra 1.0.1` と `actionview 8.1.2` の組み合わせは非互換

## いまの状態

- Aozorasearch 側には `e0ed87d` で互換 patch が入っている
- テストでは `bundle exec ruby -I test test/aozorasearch/web/app_test.rb` と `bundle exec rake test` が通る
- ただし、この patch は依存互換性問題をアプリ側で吸収しており、保守性は高くない

## 問題点

- 本来は依存で解くべき問題を、アプリ側 patch で先に塞いでいる
- `kaminari-sinatra` や `actionview` の今後の更新で再び追従が必要になる
- patch を残すなら「依存で解けない」ことの確認が必要

## 依存で解く候補

1. `actionview` / `activesupport` を 7 系へ pin する
   - `kaminari-sinatra 1.0.1` の `super()` 呼び出しと整合する可能性が高い
   - 一方で、他の更新済み依存との整合を再確認する必要がある

2. `kaminari-sinatra` 側の互換版を探す
   - `actionview 8` に対応した newer release があれば最優先候補
   - 対応版が無ければ、依存での解決余地は限定的

3. `kaminari` 利用方法を見直す
   - `kaminari-sinatra` を外して別手段で paginate する
   - 変更範囲が広く、今回の依存更新タスクとしては重い

## 推奨順序

1. `kaminari-sinatra` と `actionview` の互換版有無を確認する
2. 無ければ `actionview` / `activesupport` 7 系 pin を試す
3. それでも依存解決できない場合に限り、Aozorasearch 側 patch を暫定採用する

## 判断基準

- 依存だけで `start` と `paginate` が通るなら patch は落とす
- patch を残す場合は、暫定対応であることと代替案を commit / research に残す
- patch を残したまま merge するなら、少なくとも `/search` HTML の end-to-end テストを足す
