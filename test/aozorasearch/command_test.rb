require_relative "../test_helper"
require "open3"

class CommandTest < Minitest::Test
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

  def test_start_silent_runs_web_server_without_opening_browser
    command = Aozorasearch::Command.new([], {"silent" => true}, {})
    started_with = nil

    command.stub(:run_web_server, ->(app, host:, port:) { started_with = [app, host, port] }) do
      Launchy.stub(:open, ->(*) { flunk("silent start must not open browser") }) do
        command.start
      end
    end

    assert_equal([Aozorasearch::Web::App, "127.0.0.1", 4567], started_with)
  end
end
