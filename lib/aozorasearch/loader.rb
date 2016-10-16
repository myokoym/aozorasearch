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
require "parallel"
require "aozorasearch/groonga_database"

module Aozorasearch
  class Loader
    def load(options={})
      authors = File.read("data/authors.all.txt")
      load_proc = lambda do |line|
        puts line
        author_id, author_name = line.split(",")
        author_name.gsub!(/[\" ]/, "")
        load_by_author(author_id, author_name)
      end

      if options[:parallel]
        Parallel.each(authors.lines,
                      &load_proc)
      else
        authors.each_line(&load_proc)
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
