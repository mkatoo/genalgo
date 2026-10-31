# frozen_string_literal: true

require_relative "blx_alpha_crossover"
require_relative "simplex_crossover"
require_relative "blx_alpha_generation_strategy"
require_relative "simplex_generation_strategy"

module Genalgo
  # Minimal Generation Gap (MGG) for one execution's validated configuration.
  class MGG
    def initialize(configuration)
      @generation_strategy = create_generation_strategy(configuration)
    end

    def next_generation(population)
      @generation_strategy.next_generation(population)
    end

    def evaluations_per_generation
      @generation_strategy.evaluations_per_generation
    end

    private

    def create_generation_strategy(configuration)
      case configuration.crossover
      when :blx_alpha
        BlxAlphaGenerationStrategy.new(configuration, crossover: BlxAlphaCrossover.new)
      when :simplex
        SimplexGenerationStrategy.new(configuration, crossover: SimplexCrossover.new(configuration.n_dim))
      else
        raise StrategyError, "Unknown crossover type: #{configuration.crossover}"
      end
    end
  end
end
