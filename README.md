# Aozorasearch

The full-text search system for Aozora Bunko by Groonga

## Usage

### Prepare

    $ git clone https://github.com/myokoym/aozorasearch
    $ bundle install
    $ git submodule update --init  # Free space of 11GB is required

### Load data

    $ bundle exec ruby -I lib bin/aozorasearch load

### Run web server

    $ bundle exec ruby -I lib bin/aozorasearch start