# frozen_string_literal: true

require_relative "bounds"
require_relative "crossovers/blx_alpha"
require_relative "crossovers/simplex"

module Genalgo
  # Immutable settings, reusable across independent runs.
  class Configuration
    attr_reader :bounds, :population_size, :max_evaluations, :crossover, :seed

    def initialize(bounds:, population_size:, max_evaluations:, crossover: Crossovers::BlxAlpha.new, seed: nil)
      @bounds = bounds
      @population_size = population_size
      @max_evaluations = max_evaluations
      @crossover = crossover
      @seed = seed.nil? ? Random.new_seed : seed
      validate!
      freeze
    end

    def with(**changes)
      self.class.new(**to_h, **changes)
    end

    def to_h
      { bounds: bounds, population_size: population_size, max_evaluations: max_evaluations,
        crossover: crossover, seed: seed }
    end

    private

    def validate!
      raise ConfigurationError, "Bounds must be a Genalgo::Bounds instance" unless bounds.is_a?(Bounds)
      raise ConfigurationError, "Seed must be an integer" unless seed.is_a?(Integer)

      validate_sizes!
      validate_crossover!
      validate_parent_count!
    end

    def validate_sizes!
      { population_size: population_size, max_evaluations: max_evaluations }.each do |name, value|
        next if value.is_a?(Integer) && value.positive?

        raise ConfigurationError.new("#{name} must be a positive integer", context: { parameter: name, value: value })
      end
      return if max_evaluations >= population_size

      raise ConfigurationError, "Evaluation budget must cover the initial population"
    end

    def validate_crossover!
      return if crossover.respond_to?(:call) && crossover.respond_to?(:parent_count) && crossover.frozen?

      raise ConfigurationError, "Crossover must be immutable and implement call and parent_count"
    end

    def validate_parent_count!
      count = crossover.parent_count(bounds.dimension)
      return if count.is_a?(Integer) && count.between?(2, population_size)

      raise ConfigurationError.new("Population must cover the crossover's parent count",
                                   context: { population_size: population_size, parent_count: count })
    end
  end
end
