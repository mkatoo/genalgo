# frozen_string_literal: true

module Genalgo
  # Base exception with structured details for callers.
  class Error < StandardError
    attr_reader :context

    def initialize(message = nil, context: {})
      @context = context.dup.freeze
      super(message)
    end

    def to_s
      return super if context.empty?

      "#{super} (#{context.map { |key, value| "#{key}: #{value}" }.join(", ")})"
    end
  end

  class ConfigurationError < Error; end
  class EvaluationError < Error; end
  class PopulationError < Error; end
  class StrategyError < Error; end
end
