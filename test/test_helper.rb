$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

ENV["RACK_ENV"] = "test"

require "fileutils"
require "simplecov"
require "minitest/autorun"
require "minitest/mock"
require "rack/test"
require "tmpdir"

GENERATED_AOZORASEARCH_HOME =
  if ENV["AOZORASEARCH_HOME"].to_s.empty?
    dir = Dir.mktmpdir("aozorasearch-test-")
    ENV["AOZORASEARCH_HOME"] = dir
    dir
  else
    FileUtils.mkdir_p(ENV["AOZORASEARCH_HOME"])
    nil
  end

SimpleCov.start do
  enable_coverage :branch
  add_filter "/test/"
  track_files "lib/**/*.rb"
end

Minitest.after_run do
  FileUtils.rm_rf(GENERATED_AOZORASEARCH_HOME) if GENERATED_AOZORASEARCH_HOME
end

require "aozorasearch/command"
require "aozorasearch/web/app"
