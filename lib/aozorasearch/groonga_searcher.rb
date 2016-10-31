# class Aozorasearch::GroongaSearcher
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

module Aozorasearch
  class GroongaSearcher
    attr_reader :snippet

    def search(database, words, options={})
      books = database.books
      selected_books = select_books(books, words, options)

      @snippet = Groonga::Snippet.new(width: 100,
                                      default_open_tag: "<span class=\"keyword\">",
                                      default_close_tag: "</span>",
                                      html_escape: true,
                                      normalize: true)
      words.each do |word|
        @snippet.add_keyword(word)
      end

      order = options[:reverse] ? "ascending" : "descending"
      sorted_books = selected_books.sort([{
                                            :key => "_score",
                                            :order => order,
                                          }])

      sorted_books
    end

    private
    def select_books(books, words, options)
      selected_books = books.select do |record|
        conditions = []
        if options[:author_id]
          conditions << (record.author._key == options[:author_id])
        end
        if options[:orthography]
          conditions << (record.orthography._key == options[:orthography])
        end
        if options[:copyrighted]
          conditions << (record.copyrighted._key == options[:copyrighted])
        end
        if options[:ndc]
          conditions << (record.ndc._key == options[:ndc])
        elsif options[:ndc3]
          conditions << (record.ndc3._key == options[:ndc3])
        elsif options[:ndc2]
          conditions << (record.ndc2._key == options[:ndc2])
        elsif options[:ndc1]
          conditions << (record.ndc1._key == options[:ndc1])
        end
        if options[:age_group]
          conditions << (record.age_group._key == options[:age_group])
        end
        unless words.empty?
          match_target = record.match_target do |match_record|
              (match_record.index('Terms.Books_title') * 10) |
              (match_record.index('Terms.Books_content'))
          end
          full_text_search = words.collect {|word|
            (match_target =~ word) |
              (record.author.name =~ word)
          }.inject(&:&)
          conditions << full_text_search
        end
        conditions
      end
      selected_books
    end
  end
end
