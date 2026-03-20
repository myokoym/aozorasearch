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

  def test_start_silent_uses_sinatra_run_without_opening_browser
    command = Aozorasearch::Command.new([], {"silent" => true}, {})
    started = false

    Aozorasearch::Web::App.stub(:run!, -> { started = true }) do
      Launchy.stub(:open, ->(*) { flunk("silent start must not open browser") }) do
        command.start
      end
    end

    assert started
  end
end
