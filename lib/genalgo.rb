# frozen_string_literal: true

require_relative "genalgo/version"
require_relative "genalgo/configuration"
require_relative "genalgo/mutable_configuration"
require_relative "genalgo/bounds"
require_relative "genalgo/generation_strategy"
require_relative "genalgo/blx_alpha_generation_strategy"
require_relative "genalgo/simplex_generation_strategy"
require_relative "genalgo/executor"

module Genalgo
  # Base exception class for all Genalgo-specific errors
  class Error < StandardError
    attr_reader :context

    def initialize(message = nil, context: {})
      @context = context
      super(message)
    end

    def to_s
      base_message = super
      return base_message if context.empty?

      context_info = context.map { |k, v| "#{k}: #{v}" }.join(", ")
      "#{base_message} (#{context_info})"
    end
  end

  # Configuration-related errors (dimensions, population size, bounds, crossover types)
  class ConfigurationError < Error; end

  # Evaluation function related errors
  class EvaluationError < Error; end

  # Population management related errors
  class PopulationError < Error; end

  # Strategy-related errors (selection, crossover strategy issues)
  class StrategyError < Error; end
end
