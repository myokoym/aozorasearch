# Aozorasearch - 青空文庫 本文対応 全文検索システム

The full-text search system for [Aozora Bunko](http://www.aozora.gr.jp/) by [Groonga](http://groonga.org/ja/).

## Document

* [青空文庫をNDC等で絞り込みつつ全文検索できるWebサイト「Aozorasearch」の紹介 - Qiita](https://qiita.com/myokoym/items/a97f6901d4fa12bb8cb9)
* [VPS デプロイランブック](docs/runbooks/vps-deploy.md)

## Usage

### Prepare

    $ git clone https://github.com/myokoym/aozorasearch
    $ bash scripts/setup-codex-agents.sh
    $ bundle config set path vendor/bundle
    $ bundle install
    $ git submodule update --init  # Free space of 11GB is required

`scripts/setup-codex-agents.sh` は、`awesome-codex-subagents` からこのリポジトリで使う custom agents を取得し、ローカルの `.codex/agents/` に同期します。`.codex/agents/` 自体は commit 対象ではありません。

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

## License

* Ruby Code (.rb): LGPL 2.1 or later. See LICENSE.txt for details.
* Data from aozorabunko (submodule): Licensed by [青空文庫 (Aozora Bunko)](http://www.aozora.gr.jp/) under [CC BY 2.1 JP](https://creativecommons.org/licenses/by/2.1/jp/).
