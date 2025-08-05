# frozen_string_literal: true

require_relative "genalgo/version"
require_relative "genalgo/bounds"
require_relative "genalgo/generation_strategy"
require_relative "genalgo/blx_alpha_generation_strategy"
require_relative "genalgo/simplex_generation_strategy"
require_relative "genalgo/executor"

module Genalgo
  class Error < StandardError; end
end
