# frozen_string_literal: true

require_relative "lib/genalgo/version"

Gem::Specification.new do |spec|
  spec.name = "genalgo"
  spec.version = Genalgo::VERSION
  spec.authors = ["mkakoo"]
  spec.email = ["28562951+mkatoo@users.noreply.github.com"]

  spec.summary = "Real-coded Genetic Algorithm"
  spec.description = "Bounded real-coded genetic optimization with MGG, BLX-alpha, and Simplex crossover."
  spec.homepage = "https://github.com/mkatoo/genalgo"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["source_code_uri"] = "https://github.com/mkatoo/genalgo"
  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]
end
