# class Aozorasearch::Web::App
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

require "aozorasearch"
require "sinatra/base"
require "sinatra/json"
require "sinatra/cross_origin"
require "sinatra/reloader"
require "haml"
require "padrino-helpers"
require "kaminari/sinatra"

module Aozorasearch
  module Web
    module PaginationProxy
      def limit_value
        page_size
      end

      def total_pages
        n_pages
      end
    end

    class App < Sinatra::Base
      helpers Kaminari::Helpers::SinatraHelpers
      register Sinatra::CrossOrigin

      configure :development do
        register Sinatra::Reloader
      end

      get "/" do
        haml :index
      end

      get "/search" do
        search_and_paginate
        haml :index
      end

      get "/search.json" do
        cross_origin
        search_and_paginate
        books = @paginated_books || @books
        json books.collect {|book| book.attributes }
      end

      helpers do
        def search_and_paginate
          if params[:word]
            words = params[:word].split(/[[:space:]]+/)
          else
            words = []
          end
          options ||= {}
          options[:author_id] = params[:author_id] if params[:author_id]
          options[:orthography] = params[:orthography] if params[:orthography]
          options[:copyrighted] = params[:copyrighted] if params[:copyrighted]
          options[:ndc1] = params[:ndc1] if params[:ndc1]
          options[:ndc2] = params[:ndc2] if params[:ndc2]
          options[:ndc3] = params[:ndc3] if params[:ndc3]

          database = GroongaDatabase.new
          database.open(Command.new.database_dir)
          searcher = GroongaSearcher.new
          @books = searcher.search(database, words, options)
          @snippet = searcher.snippet
          page = (params[:page] || 1).to_i
          size = (params[:n_per_page] || 20).to_i
          @paginated_books = @books.paginate([["_score", :desc]],
                                             page: page,
                                             size: size)
          @paginated_books.extend(PaginationProxy)
          @paginated_books
        end

        def grouping(table)
          key = "author"
          table.group(key).sort_by {|item| item.n_sub_records }.reverse
        end

        def drilled_url(author)
          url(["/search", drilled_params(author_id: author._key)].join("?"))
        end

        def drilled_label(author)
          "#{author.name} (#{author.n_sub_records})"
        end

        def drilled_params(additional_params)
          tmp_params = params.dup
          tmp_params.merge!(additional_params)
          tmp_params.delete("page")
          tmp_params.to_param
        end

        def groonga_version
          Groonga::VERSION[0..2].join(".")
        end

        def rroonga_version
          Groonga::BINDINGS_VERSION.join(".")
        end

        def snippets
          snippet = Groonga::Snippet.new(width: 100,
                                         default_open_tag: "<span class=\"keyword\">",
                                         default_close_tag: "</span>",
                                         html_escape: true,
                                         normalize: true)
          words.each do |word|
            snippet.add_keyword(word)
          end

          snippet.execute(selected_books.first.content)
        end
      end
    end
  end
end
