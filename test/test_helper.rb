$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

ENV["RACK_ENV"] = "test"
ENV["AOZORASEARCH_HOME"] ||= File.expand_path("../tmp/test-home", __dir__)

require "fileutils"
require "simplecov"
require "minitest/autorun"
require "minitest/mock"
require "rack/test"

SimpleCov.start do
  enable_coverage :branch
  add_filter "/test/"
  track_files "lib/**/*.rb"
end

FileUtils.rm_rf(ENV["AOZORASEARCH_HOME"])
FileUtils.mkdir_p(ENV["AOZORASEARCH_HOME"])

Minitest.after_run do
  FileUtils.rm_rf(ENV["AOZORASEARCH_HOME"])
end

require "aozorasearch/command"
require "aozorasearch/web/app"
