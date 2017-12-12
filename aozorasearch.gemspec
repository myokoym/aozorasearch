lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aozorasearch/version'

Gem::Specification.new do |spec|
  spec.name          = "aozorasearch"
  spec.version       = Aozorasearch::VERSION
  spec.authors       = ["Masafumi Yokoyama"]
  spec.email         = ["myokoym@gmail.com"]
  spec.description   = %q{The full-text search system for Aozora Bunko by Groonga (via Rroonga) with Ruby.}
  spec.summary       = %q{Full-Text Search system for Aozora Bunko}
  spec.homepage      = "http://myokoym.net/aozorasearch/"
  spec.license       = "LGPLv2.1+"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("rroonga", ">= 5.0.0")
  spec.add_runtime_dependency("nokogiri")
  spec.add_runtime_dependency("thor")
  spec.add_runtime_dependency("parallel")
  spec.add_runtime_dependency("rubyzip")
  spec.add_runtime_dependency("sinatra")
  spec.add_runtime_dependency("sinatra-contrib")
  spec.add_runtime_dependency("sinatra-cross_origin")
  spec.add_runtime_dependency("padrino-helpers")
  spec.add_runtime_dependency("kaminari")
  spec.add_runtime_dependency("kaminari-sinatra")
  spec.add_runtime_dependency("haml")
  spec.add_runtime_dependency("launchy")
  spec.add_runtime_dependency("racknga")

  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rake")
end
