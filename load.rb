#!/usr/bin/env ruby

require "nkf"
require "groonga"
require "nokogiri"

Groonga::Database.open("db/db") do |database|
  authors = File.read("authors.txt")
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
      books.add(
        basename,
        title: title,
        author: doc.css(".author").text,
        author_id: author_id,
        book_id: book_id,
        body: html.encode("utf-8", encoding)
      )
    end
  end
end
