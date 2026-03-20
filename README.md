# Aozorasearch - 青空文庫 本文対応 全文検索システム

The full-text search system for [Aozora Bunko](http://www.aozora.gr.jp/) by [Groonga](http://groonga.org/ja/).

## Document

* [青空文庫をNDC等で絞り込みつつ全文検索できるWebサイト「Aozorasearch」の紹介 - Qiita](https://qiita.com/myokoym/items/a97f6901d4fa12bb8cb9)

## Usage

### Prepare

    $ git clone https://github.com/myokoym/aozorasearch
    $ bundle config set path vendor/bundle
    $ bundle install
    $ git submodule update --init  # Free space of 11GB is required

Ruby 3.2 系でのローカル検証を前提にしています。

Ubuntu 系では、少なくとも次の package が必要です。

    $ sudo apt-get install -y ruby-dev build-essential pkg-config groonga libgroonga-dev groonga-bin

### Run tests

    $ bundle exec rake test

### Load data

    $ bundle exec ruby -I lib bin/aozorasearch load

### Run web server

    $ bundle exec ruby -I lib bin/aozorasearch start

### Check CLI

    $ bundle exec ruby -I lib bin/aozorasearch version

### Remaining TODOs

- `bundle exec ruby -I lib bin/aozorasearch start` の実 HTTP 起動確認は、loopback socket を開ける実環境で最終確認する
- `thor` の `DidYouMean` deprecation warning は残っているため、必要なら Thor 系の追加更新を検討する
- `activesupport` / `padrino-helpers` / `kaminari-sinatra` の warning は残っているため、必要なら別タスクで整理する

### Merge Worktree Back To master

この作業は `feature/library-upgrade` ブランチを `.worktrees/library-upgrade` で進めている前提です。

1. worktree 側で最新の検証を実行する

       $ cd /home/myokoym/dev/web/aozorasearch/.worktrees/library-upgrade
       $ bundle exec rake test
       $ bundle exec ruby -I lib bin/aozorasearch version

2. 本流 `master` へ取り込む

       $ cd /home/myokoym/dev/web/aozorasearch
       $ git checkout master
       $ git merge feature/library-upgrade

3. 取り込み後に `master` 側で再検証する

       $ bundle exec rake test
       $ bundle exec ruby -I lib bin/aozorasearch version

4. 問題なければ worktree と feature branch を片付ける

       $ git worktree remove .worktrees/library-upgrade
       $ git branch -d feature/library-upgrade

## License

* Ruby Code (.rb): LGPL 2.1 or later. See LICENSE.txt for details.
* Data from aozorabunko (submodule): Licensed by [青空文庫 (Aozora Bunko)](http://www.aozora.gr.jp/) under [CC BY 2.1 JP](https://creativecommons.org/licenses/by/2.1/jp/).
