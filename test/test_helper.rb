$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

ENV["RACK_ENV"] = "test"
ENV["AOZORASEARCH_HOME"] ||= File.expand_path("tmp/test-home", __dir__)

require "fileutils"
require "minitest/autorun"
require "minitest/mock"
require "rack/test"

FileUtils.mkdir_p(ENV["AOZORASEARCH_HOME"])

require "aozorasearch/command"
require "aozorasearch/web/app"
