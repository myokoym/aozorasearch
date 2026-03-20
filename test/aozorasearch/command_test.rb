require_relative "../test_helper"
require "open3"

class CommandTest < Minitest::Test
  FakeThread = Struct.new(:joined) do
    def join
      self.joined = true
    end
  end

  def test_version_prints_current_version
    command = Aozorasearch::Command.new([], {}, {})

    stdout, = capture_io do
      command.version
    end

    assert_equal("#{Aozorasearch::VERSION}\n", stdout)
  end

  def test_cli_version_command_succeeds_without_test_env
    stdout, stderr, status = Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.expand_path("../../Gemfile", __dir__),
        "RACK_ENV" => "development"
      },
      "bundle",
      "exec",
      "ruby",
      "-I",
      "lib",
      "bin/aozorasearch",
      "version",
      chdir: File.expand_path("../..", __dir__)
    )

    assert status.success?, stderr
    assert_equal("#{Aozorasearch::VERSION}\n", stdout)
  end

  def test_start_silent_uses_sinatra_run_without_opening_browser
    command = Aozorasearch::Command.new([], {"silent" => true}, {})
    fake_thread = FakeThread.new(false)

    command.stub(:start_web_server_in_background, fake_thread) do
      Launchy.stub(:open, ->(*) { flunk("silent start must not open browser") }) do
        command.start
      end
    end

    assert fake_thread.joined
  end

  def test_start_opens_browser_with_runtime_url
    command = Aozorasearch::Command.new([], {}, {})
    fake_thread = FakeThread.new(false)
    opened_url = nil

    original_port = ENV["PORT"]
    original_bind = ENV["BIND"]
    ENV["PORT"] = "5678"
    ENV["BIND"] = "0.0.0.0"

    command.stub(:start_web_server_in_background, fake_thread) do
      Launchy.stub(:open, ->(url) { opened_url = url }) do
        command.start
      end
    end

    assert_equal("http://localhost:5678", opened_url)
    assert fake_thread.joined
  ensure
    ENV["PORT"] = original_port
    ENV["BIND"] = original_bind
  end

  def test_run_web_server_passes_single_thread_puma_settings
    command = Aozorasearch::Command.new([], {}, {})
    started_with = nil

    Aozorasearch::Web::App.stub(:run!, ->(options = {}) { started_with = options }) do
      command.send(:run_web_server)
    end

    assert_equal(
      {
        server: "puma",
        bind: "127.0.0.1",
        port: 4567,
        server_settings: {
          Threads: "1:1",
        },
      },
      started_with,
    )
  end

  def test_browser_url_uses_runtime_port_and_maps_wildcard_bind_to_localhost
    command = Aozorasearch::Command.new([], {}, {})

    original_port = ENV["PORT"]
    original_bind = ENV["BIND"]
    ENV["PORT"] = "5678"
    ENV["BIND"] = "0.0.0.0"

    assert_equal("http://localhost:5678", command.send(:browser_url))
  ensure
    ENV["PORT"] = original_port
    ENV["BIND"] = original_bind
  end

  def test_browser_url_wraps_ipv6_bind_in_brackets
    command = Aozorasearch::Command.new([], {}, {})

    original_bind = ENV["BIND"]
    ENV["BIND"] = "::1"

    assert_equal("http://[::1]:4567", command.send(:browser_url))
  ensure
    ENV["BIND"] = original_bind
  end
end
