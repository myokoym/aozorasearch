# class Aozorasearch::Command
#
# Copyright (C) 2016  Masafumi Yokoyama <myokoym@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "thor"
require "parallel"
require "launchy"
require "aozorasearch/version"
require "aozorasearch/groonga_database"
require "aozorasearch/groonga_searcher"
require "aozorasearch/loader"
require "aozorasearch/web"

module Aozorasearch
  class Command < Thor
    map "-v" => :version

    attr_reader :database_dir

    def initialize(*args)
      super
      default_base_dir = File.join(File.expand_path("~"), ".aozorasearch")
      @base_dir = ENV["AOZORASEARCH_HOME"] || default_base_dir
      @database_dir = File.join(@base_dir, "db")
    end

    desc "version", "Show version number."
    def version
      puts Aozorasearch::VERSION
    end

    desc "load", "Load books."
    option :parallel, :type => :boolean, :desc => "run on multiple processes"
    def load
      GroongaDatabase.new.open(@database_dir) do |database|
        Loader.new.load
      end
    end

    desc "search WORD", "Search books from local database."
    def search(*words)
      if words.empty? &&
         (options["resource"].nil? || options["resource"].empty?)
        $stderr.puts "WARNING: required one of word or resource option."
        return 1
      end

      GroongaDatabase.new.open(@database_dir) do |database|
        searcher = GroongaSearcher.new
        sorted_books = searcher.search(database, words, options)
        sorted_books.each do |book|
          puts "#{book.title} #{book.author_name}"
        end
      end
    end

    desc "start", "Start web server."
    option :silent, :type => :boolean, :desc => "Don't open in browser"
    def start
      web_server_thread = Thread.new { Aozorasearch::Web::App.run! }
      Launchy.open("http://localhost:4567") unless options[:silent]
      web_server_thread.join
    end
  end
end
