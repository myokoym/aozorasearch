# class Aozorasearch::Loader
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

require "csv"
require "nkf"
require "nokogiri"
require "parallel"
require "zip"
require "aozorasearch/groonga_database"
require "aozorasearch/book"

module Aozorasearch
  class Loader
    def load(options={})
      books = []
      Zip::File.open("aozorabunko/index_pages/list_person_all_extended_utf8.zip") do |zip_file|
        entry = zip_file.glob("*.csv").first
        authors_csv = entry.get_input_stream.read
        authors_csv.force_encoding(Encoding::UTF_8)
        CSV.new(authors_csv,
                headers: true,
                converters: nil).each do |row|
          books << Book.new(row)
        end
      end

      load_proc = lambda do |book|
        load_book(book)
      end

      if options[:parallel]
        Parallel.each(books, &load_proc)
      else
        books.each(&load_proc)
      end
    end

    private
    def load_book(book)
      author = Groonga["Authors"][book.author_id]
      unless author
        author = Groonga["Authors"].add(
          book.author_id,
          name: book.author_name
        )
      end

      path = book.html_url.scan(/\/cards\/.*/).first
      return unless path
      puts "#{book.name} - #{book.author_name}"
      html = File.read(File.join("aozorabunko", path))
      encoding = NKF.guess(html).to_s
      doc = Nokogiri::HTML.parse(html, nil, encoding)
      title = book.title
      unless book.subtitle.empty?
        title += " #{book.subtitle}"
      end
      content = ""
      doc.search("body .main_text").children.each do |node|
        case node.node_name
        when "text"
          content += node.text
        end
      end
      Groonga["Books"].add(
        book.id,
        title: title,
        content: content,
        author: author,
        card_url: book.card_url,
        html_url: book.html_url,
        orthography: book.orthography,
        copyrighted: book.copyrighted,
        ndc: book.ndc,
        ndc1: book.ndc1,
        ndc2: book.ndc2,
        ndc3: book.ndc3,
      )
    end
  end
end
