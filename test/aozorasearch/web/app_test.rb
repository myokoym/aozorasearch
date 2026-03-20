require_relative "../../test_helper"
require "open3"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  FakeBook = Struct.new(:_key, :attributes, keyword_init: true)

  class FakeBooks
    def initialize(books)
      @books = books
    end

    def paginate(_sort_keys, page:, size:)
      self.class.new(@books.first(size))
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
end
