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

module Aozorasearch
  class Loader
    def load(options={})
      authors = {}
      Zip::File.open("aozorabunko/index_pages/list_person_all_utf8.zip") do |zip_file|
        entry = zip_file.glob("*.csv").first
        authors_csv = entry.get_input_stream.read
        authors_csv.force_encoding(Encoding::UTF_8)
        CSV.new(authors_csv,
                headers: true,
                converters: nil).each do |row|
          id = row[0]
          name = row[1]
          authors[id] = name
        end
      end

      load_proc = lambda do |(id, name)|
        puts "#{id} #{name}"
        load_by_author(id, name)
      end

      if options[:parallel]
        Parallel.each(authors, &load_proc)
      else
        authors.each(&load_proc)
      end
    end

    private
    def load_by_author(author_id, author_name)
      author = Groonga["Authors"].add(
        author_id,
        name: author_name
      )
      Dir.glob("aozorabunko/cards/#{author_id}/files/*.html") do |path|
        html = File.read(path)
        encoding = NKF.guess(html).to_s
        doc = Nokogiri::HTML.parse(html, nil, encoding)
        basename = File.basename(path)
        if /\A\d+_/ =~ basename
          book_id = basename.split("_")[0]
        else
          book_id = basename.split(".")[0]
        end
        title = doc.css(".title").text
        subtitle = doc.css(".subtitle").text
        unless subtitle.empty?
          title += " #{subtitle}"
        end
        content = ""
        doc.search("body .main_text").children.each do |node|
          case node.node_name
          when "text"
            content += node.text
          end
        end
        Groonga["Books"].add(
          book_id,
          title: title,
          content: content,
          author: author
        )
      end
    end
  end
end
