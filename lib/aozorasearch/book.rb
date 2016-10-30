module Aozorasearch
  class Book
    attr_reader :id
    attr_reader :title
    attr_reader :title_kana
    attr_reader :subtitle
    attr_reader :ndc
    attr_reader :ndc1
    attr_reader :ndc2
    attr_reader :ndc3
    attr_reader :orthography
    attr_reader :copyrighted
    attr_reader :created_date
    attr_reader :updated_date
    attr_reader :card_url
    attr_reader :author_id
    attr_reader :author_last_name
    attr_reader :author_first_name
    attr_reader :author_birthdate
    attr_reader :author_botudate
    attr_reader :first_edition_year
    attr_reader :editor
    attr_reader :proofreader
    attr_reader :txt_url
    attr_reader :txt_updated_date
    attr_reader :html_url
    attr_reader :html_updated_date
    attr_reader :name
    attr_reader :author_name
    def initialize(row)
      @id                 = row[0]
      @title              = row[1]
      @title_kana         = row[2]
      @subtitle           = row[4]
      @classification     = row[8]
      @orthography        = row[9]
      @copyrighted        = row[10]
      @created_date       = row[11]
      @updated_date       = row[12]
      @card_url           = row[13]
      @author_id          = row[14]
      @author_last_name   = row[15]
      @author_first_name  = row[16]
      @author_birthdate   = row[24]
      @author_botudate    = row[25]
      @first_edition_year = row[29]
      @editor             = row[43]
      @proofreader        = row[44]
      @txt_url            = row[45]
      @txt_updated_date   = row[46]
      @html_url           = row[50]
      @html_updated_date  = row[51]

      @name = @title
      unless @subtitle.empty?
        @name += " #{@subtitle}"
      end
      @author_name = [@author_last_name, @author_first_name].join

      if /\ANDC (.*)/ =~ @classification
        @ndc = $1.split(/[[:space:]]/)
        @ndc1 = @ndc.map {|ndc| ndc[-3] + "00" }.uniq
        @ndc2 = @ndc.map {|ndc| ndc[-3..-2] + "0" }.uniq
        @ndc3 = @ndc.map {|ndc| ndc[-3..-1] }.uniq
      end
    end
  end
end
