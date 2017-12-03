# Aozorasearch - 青空文庫 本文対応 全文検索システム

The full-text search system for [Aozora Bunko](http://www.aozora.gr.jp/) by [Groonga](http://groonga.org/ja/).

## Usage

### Prepare

    $ git clone https://github.com/myokoym/aozorasearch
    $ bundle install
    $ git submodule update --init  # Free space of 11GB is required

### Load data

    $ bundle exec ruby -I lib bin/aozorasearch load

### Run web server

    $ bundle exec ruby -I lib bin/aozorasearch start

## License

* Ruby Code (.rb): LGPL 2.1 or later. See LICENSE.txt for details.
* Data in aozorabunko (submodule): Licensed by [青空文庫 (Aozora Bunko)](http://www.aozora.gr.jp/) under [CC BY 2.1 JP](https://creativecommons.org/licenses/by/2.1/jp/).
