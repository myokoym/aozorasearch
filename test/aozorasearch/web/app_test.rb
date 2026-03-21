require_relative "../../test_helper"
require "open3"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  FakeAuthor = Struct.new(:name, keyword_init: true)
  FakeBook = Struct.new(:_key, :title, :card_url, :html_url, :authors, :content, :attributes, keyword_init: true)
  FakeSnippet = Struct.new(:result) do
    def execute(_content)
      Array(result)
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
    def initialize(books, total_count: books.length, empty: books.empty?)
      @books = books
      @total_count = total_count
      @empty = empty
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
    ], total_count: 40, empty: true)
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
