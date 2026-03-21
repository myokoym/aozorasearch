require_relative "../../test_helper"
require "open3"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  FakeAuthor = Struct.new(:name, keyword_init: true)
  FakeBook = Struct.new(:_key, :title, :card_url, :html_url, :authors, :content, :attributes, keyword_init: true)
  FakeGroupRecord = Struct.new(:_key, :name, :label, :n_sub_records, keyword_init: true)
  FakeSnippet = Struct.new(:result) do
    def execute(_content)
      Array(result)
    end
  end

  class FakeGroupedBooks
    include Enumerable

    def initialize(items)
      @items = items
    end

    def each(&block)
      @items.each(&block)
    end

    def sort(_sort_keys = nil)
      self.class.new(@items.sort_by { |item| item._key.to_s })
    end

    def sort_by(&block)
      self.class.new(@items.sort_by(&block))
    end

    def reverse
      self.class.new(@items.reverse)
    end
  end

  class FakePaginatedBooks
    include Enumerable

    attr_reader :n_pages, :n_records, :page_size, :start_offset, :end_offset

    def initialize(books, page:, size:, total_count:)
      @books = books
      @page = page
      @page_size = size
      @n_records = total_count
      @n_pages = (total_count.to_f / size).ceil
      @start_offset = ((page - 1) * size) + 1
      @end_offset = @start_offset + books.length - 1
    end

    def current_page
      @page
    end

    def prev_page
      @page > 1 ? (@page - 1) : nil
    end

    def next_page
      @page < @n_pages ? (@page + 1) : nil
    end

    def each(&block)
      @books.each(&block)
    end
  end

  class FakeBooks
    def initialize(books, total_count: books.length, empty: books.empty?, groups: {})
      @books = books
      @total_count = total_count
      @empty = empty
      @groups = groups
    end

    def paginate(_sort_keys, page:, size:)
      offset = (page - 1) * size
      FakePaginatedBooks.new(@books.slice(offset, size) || [],
                             page: page,
                             size: size,
                             total_count: @total_count)
    end

    def map(&block)
      @books.map(&block)
    end

    def collect(&block)
      @books.collect(&block)
    end

    def to_a
      @books
    end

    def empty?
      @empty
    end

    def group(name)
      FakeGroupedBooks.new(@groups.fetch(name.to_s, []))
    end
  end

  class FakeDatabase
    def open(_path)
      self
    end

    def authors
      {}
    end
  end

  def app
    Aozorasearch::Web::App
  end

  def test_root_returns_ok
    get "/"

    assert last_response.ok?
  end

  def test_search_json_returns_stubbed_results
    fake_books = FakeBooks.new([
      FakeBook.new(_key: "1", attributes: {"title" => "stub"})
    ])
    fake_searcher = Minitest::Mock.new
    fake_searcher.expect(:search, fake_books, [FakeDatabase, ["stub"], Hash])
    fake_searcher.expect(:snippet, nil)

    Aozorasearch::GroongaDatabase.stub(:new, FakeDatabase.new) do
      Aozorasearch::GroongaSearcher.stub(:new, fake_searcher) do
        get "/search.json", word: "stub"
      end
    end

    assert last_response.ok?
    assert_includes(last_response.body, "stub")
    fake_searcher.verify
  end

  def test_search_html_renders_paginate_links_with_stubbed_results
    fake_books = FakeBooks.new([
      FakeBook.new(
        _key: "1",
        title: "stub title 1",
        card_url: "https://example.com/books/1",
        html_url: "https://example.com/books/1.html",
        authors: [FakeAuthor.new(name: "author 1")],
        content: "stub content 1",
        attributes: {"title" => "stub title 1"},
      ),
      FakeBook.new(
        _key: "2",
        title: "stub title 2",
        card_url: "https://example.com/books/2",
        html_url: "https://example.com/books/2.html",
        authors: [FakeAuthor.new(name: "author 2")],
        content: "stub content 2",
        attributes: {"title" => "stub title 2"},
      ),
    ], total_count: 40, empty: false, groups: {
      "authors" => [
        FakeGroupRecord.new(_key: "a1", name: "author 1", n_sub_records: 2),
      ],
      "ndc1" => [
        FakeGroupRecord.new(_key: "9", label: "文学", n_sub_records: 2),
      ],
      "kids" => [
        FakeGroupRecord.new(_key: true, n_sub_records: 1),
      ],
      "orthography" => [
        FakeGroupRecord.new(_key: "新字新仮名", n_sub_records: 2),
      ],
      "copyrighted" => [
        FakeGroupRecord.new(_key: "なし", n_sub_records: 2),
      ],
      "age_group" => [
        FakeGroupRecord.new(_key: "1890", n_sub_records: 1),
      ],
    })
    fake_searcher = Minitest::Mock.new
    fake_searcher.expect(:search, fake_books, [FakeDatabase, ["stub"], Hash])
    fake_searcher.expect(:snippet, FakeSnippet.new(["stub snippet"]))

    Aozorasearch::GroongaDatabase.stub(:new, FakeDatabase.new) do
      Aozorasearch::GroongaSearcher.stub(:new, fake_searcher) do
        get "/search", word: "stub"
      end
    end

    assert last_response.ok?, last_response.body
    assert_includes(last_response.body, "stub title 1")
    assert_includes(last_response.body, "?page=2")
    assert_includes(last_response.body, "author 1")
    assert_includes(last_response.body, "文学")
    fake_searcher.verify
  end

  def test_search_with_reset_params_redirects_to_word_only_query
    get "/search", word: "stub", author_id: "1", reset_params: "1"

    assert last_response.redirect?
    assert_equal("http://example.org/search?word=stub", last_response.location)
  end

  def test_similar_get_returns_ok
    get "/similar"

    assert last_response.ok?
    assert_includes(last_response.body, "類似文書検索")
  end

  def test_similar_post_renders_stubbed_results
    fake_searcher = Minitest::Mock.new
    fake_searcher.expect(:similar_search_by_text, [
      FakeBook.new(
        _key: "1",
        title: "similar title",
        card_url: "https://example.com/books/1",
        html_url: "https://example.com/books/1.html",
        authors: [FakeAuthor.new(name: "author 1")],
        content: "similar content",
        attributes: {"title" => "similar title"},
      ),
    ], [FakeDatabase, "stub text"])

    Aozorasearch::GroongaDatabase.stub(:new, FakeDatabase.new) do
      Aozorasearch::GroongaSearcher.stub(:new, fake_searcher) do
        post "/similar", text: "stub text"
      end
    end

    assert last_response.ok?, last_response.body
    assert_includes(last_response.body, "similar title")
    fake_searcher.verify
  end

  def test_bookmarks_renders_stubbed_results
    fake_searcher = Minitest::Mock.new
    fake_searcher.expect(:bookmarks, [
      FakeBook.new(
        _key: "1",
        title: "bookmark title",
        card_url: "https://example.com/books/1",
        html_url: "https://example.com/books/1.html",
        authors: [FakeAuthor.new(name: "author 1")],
        content: "bookmark content",
        attributes: {"title" => "bookmark title"},
      ),
    ], [FakeDatabase, "1"])

    Aozorasearch::GroongaDatabase.stub(:new, FakeDatabase.new) do
      Aozorasearch::GroongaSearcher.stub(:new, fake_searcher) do
        get "/bookmarks", ids: "1"
      end
    end

    assert last_response.ok?, last_response.body
    assert_includes(last_response.body, "bookmark title")
    fake_searcher.verify
  end

  def test_loading_app_in_development_succeeds
    stdout, stderr, status = Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.expand_path("../../../Gemfile", __dir__),
        "RACK_ENV" => "development"
      },
      "bundle",
      "exec",
      "ruby",
      "-e",
      'require "./lib/aozorasearch/web/app"; puts "ok"',
      chdir: File.expand_path("../../..", __dir__)
    )

    assert status.success?, stderr
    assert_equal("ok\n", stdout)
  end

  def test_development_registers_sinatra_reloader
    stdout, stderr, status = Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.expand_path("../../../Gemfile", __dir__),
        "RACK_ENV" => "development"
      },
      "bundle",
      "exec",
      "ruby",
      "-e",
      'require "./lib/aozorasearch/web/app"; puts(Aozorasearch::Web::App.extensions.include?(Sinatra::Reloader) ? "ok" : "ng")',
      chdir: File.expand_path("../../..", __dir__)
    )

    assert status.success?, stderr
    assert_equal("ok\n", stdout)
  end

  def test_webrick_is_available_for_local_server_start
    stdout, stderr, status = Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.expand_path("../../../Gemfile", __dir__)
      },
      "bundle",
      "exec",
      "ruby",
      "-e",
      'require "webrick"; puts "ok"',
      chdir: File.expand_path("../../..", __dir__)
    )

    assert status.success?, stderr
    assert_equal("ok\n", stdout)
  end

  def test_rackup_and_puma_are_available_for_sinatra_start
    stdout, stderr, status = Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.expand_path("../../../Gemfile", __dir__)
      },
      "bundle",
      "exec",
      "ruby",
      "-e",
      'require "rackup"; require "puma"; puts "ok"',
      chdir: File.expand_path("../../..", __dir__)
    )

    assert status.success?, stderr
    assert_equal("ok\n", stdout)
  end
end
