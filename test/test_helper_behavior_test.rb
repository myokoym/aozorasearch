require_relative "test_helper"
require "open3"
require "tmpdir"

class TestHelperBehaviorTest < Minitest::Test
  def test_blank_aozorasearch_home_uses_generated_tmpdir
    stdout, stderr, status = Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.expand_path("../Gemfile", __dir__),
        "AOZORASEARCH_HOME" => "",
      },
      "bundle",
      "exec",
      "ruby",
      "-I",
      "test",
      "-e",
      'ENV["MT_NO_AUTORUN"] = "1"; require "./test/test_helper"; puts "HOME=#{ENV["AOZORASEARCH_HOME"]}"',
      chdir: File.expand_path("..", __dir__),
    )

    assert status.success?, stderr
    assert_match(%r{\AHOME=#{Regexp.escape(Dir.tmpdir)}/aozorasearch-test-}, stdout)
  end
end
