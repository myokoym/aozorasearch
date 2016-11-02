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
      I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
      I18n.available_locales = [:ja, :en, :"ja-JP"]
      I18n.default_locale = :ja
      helpers Kaminari::Helpers::SinatraHelpers
      register Sinatra::CrossOrigin

      configure :development do
        register Sinatra::Reloader
      end

      get "/" do
        haml :index
      end

      get "/search" do
        if params[:reset_params]
          params.reject! do |key, _value|
            key != "word"
          end
          redirect to('/search?' + params.to_param)
        end
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
          options[:ndc] = params[:ndc] if params[:ndc]
          options[:age_group] = params[:age_group] if params[:age_group]
          options[:kids] = params[:kids] if params[:kids]

          database = GroongaDatabase.new
          database.open(Command.new.database_dir)
          searcher = GroongaSearcher.new
          @books = searcher.search(database, words, options)
          @snippet = searcher.snippet
          page = (params[:page] || 1).to_i
          size = (params[:n_per_page] || 20).to_i
          begin
            @paginated_books = @books.paginate([["_score", :desc]],
                                               page: page,
                                               size: size)
          rescue Groonga::TooLargePage
            params.delete(:page)
            @paginated_books = @books.paginate([["_score", :desc]],
                                               page: 1,
                                               size: size)
          end
          @paginated_books.extend(PaginationProxy)
          @paginated_books
        end

        def params_to_description
          words = []
          if params[:author_id]
            words << "著者ID:#{params[:author_id]}"
          end
          if params[:ndc] || params[:ndc3] || params[:ndc2] || params[:ndc1]
            words << "NDC #{params[:ndc] || params[:ndc3] || params[:ndc2] || params[:ndc1]}"
          end
          if params[:kids]
            words << "児童書"
          end
          if params[:age_group]
            words << "#{params[:age_group].sub(/\A0+/, "")}年代生まれの作家"
          end
          if params[:orthography]
            words << params[:orthography]
          end
          if params[:copyrighted]
            words << "著作権#{params[:copyrighted]}"
          end
          if words.empty?
            ""
          else
            words.collect! do |word|
              "「#{word}」"
            end
            "（#{words.join}で絞り込み中）"
          end
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
          additional_params = Hash[
            additional_params.map do |key, value|
              [key.to_s, value]
            end
          ]
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

        def last_update_time
          path = File.join(settings.root, "..", "..", "..", "aozorabunko")
          if File.exist?(path)
            File.mtime(path)
          else
            nil
          end
        end

        def last_update_date
          return unless last_update_time
          last_update_time.strftime("%Y-%m-%d")
        end
      end
    end
  end
end
