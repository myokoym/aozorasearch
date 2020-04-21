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
require "active_support/core_ext/hash"
require "sinatra/base"
require "sinatra/json"
require "sinatra/cross_origin"
require "sinatra/reloader"
require "json"
require "haml"
require "padrino-helpers"
require "kaminari/sinatra"

require_relative "aozorasearch-kaminari"

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

      before do
        @sub_url = ENV["AOZORASEARCH_SUB_URL"]
        if params.include?(:ndc1) || params.include?(:ndc2) || params.include?(:ndc3)
          ndc_data_path = File.join(settings.root, "..", "..", "..", "data", "ndc-simple.json")
          @ndc_table = JSON.load(File.read(ndc_data_path))
        end
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

      get "/similar" do
        haml :similar
      end

      post "/similar" do
        database = GroongaDatabase.new
        database.open(Command.new.database_dir)
        searcher = GroongaSearcher.new
        text = params[:text] || ""
        @books = searcher.similar_search_by_text(database, text).take(50)
        haml :similar
      end

      helpers do
        def search_and_paginate
          if params[:word]
            words = params[:word].strip.split(/[[:space:]]+/)
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
          if params[:author_id]
            @drilled_author_name = database.authors[params[:author_id]]&.name
          end
        end

        def params_to_description
          words = []
          if params[:author_id]
            words << "著者: #{@drilled_author_name || params[:author_id]}"
          end
          if params[:ndc3]
            words << "NDC #{params[:ndc3]} #{ndc_to_label(params[:ndc3])}"
          elsif params[:ndc2]
            words << "NDC #{params[:ndc2]&.[](0..1)} #{ndc_to_label(params[:ndc2])}"
          elsif params[:ndc1]
            words << "NDC #{params[:ndc1]&.[](0)} #{ndc_to_label(params[:ndc1])}"
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

        def ndc_to_label(ndc)
          return ndc unless @ndc_table
          @ndc_table[ndc.to_s]
        end

        def drilled_params(additional_params, deletion_keys=nil)
          additional_params = Hash[
            additional_params.map do |key, value|
              [key.to_s, value]
            end
          ]
          tmp_params = params.dup
          tmp_params.merge!(additional_params)
          tmp_params.delete("page")
          if deletion_keys.is_a?(Array)
            deletion_keys.each do |key|
              tmp_params.delete(key)
            end
          else
            tmp_params.delete(deletion_keys)
          end
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
          path = File.join(settings.root, "..", "..", "..", ".aozorasearch", "db", "aozorasearch.db")
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

        def page_title
          title = "Aozorasearch 青空文庫全文検索"
          if params[:word]
            title = "#{params[:word]}#{params_to_description} - #{title}"
          end
          title
        end
      end
    end
  end
end
