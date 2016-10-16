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

require "nkf"
require "nokogiri"
require "aozorasearch/groonga_database"

module Aozorasearch
  class Loader
    def load
      authors = File.read("data/authors.txt")
      authors.each_line do |line|
        puts line
        author_id = line.split(",")[0]
        Dir.glob("aozorabunko/cards/#{author_id}/files/*.html") do |path|
          html = File.read(path)
          encoding = NKF.guess(html).to_s
          doc = Nokogiri::HTML.parse(html, nil, encoding)
          books = Groonga["Books"]
          basename = File.basename(path)
          if /\A\d+_/ =~ basename
            book_id = basename.split("_")[0]
          else
            book_id = basename.split(".")[0]
          end
          title = doc.css(".title").text
          subtitle = doc.css(".subtitle").text
          if subtitle
            title = [title, subtitle].join(" ")
          end
          content = ""
          doc.search("body .main_text").children.each do |node|
            case node.node_name
            when "text"
              content += node.text
            end
          end
          books.add(
            book_id,
            title: title,
            author_name: doc.css(".author").text,
            #author_id: author_id,
            #book_id: book_id,
            content: content
          )
        end
      end
    end
  end
end
