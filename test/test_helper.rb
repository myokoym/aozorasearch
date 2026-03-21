$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

ENV["RACK_ENV"] = "test"

require "fileutils"
require "simplecov"
require "minitest/autorun"
require "minitest/mock"
require "rack/test"
require "tmpdir"

GENERATED_AOZORASEARCH_HOME = ENV["AOZORASEARCH_HOME"] ? nil : Dir.mktmpdir("aozorasearch-test-")
ENV["AOZORASEARCH_HOME"] ||= GENERATED_AOZORASEARCH_HOME
FileUtils.mkdir_p(ENV["AOZORASEARCH_HOME"]) unless GENERATED_AOZORASEARCH_HOME

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
