# frozen_string_literal: true

require_relative "blx_alpha_crossover"
require_relative "simplex_crossover"
require_relative "elite_roulette_selection"
require_relative "blx_alpha_generation_strategy"
require_relative "simplex_generation_strategy"

module Genalgo
  # Orchestrates generation evolution using specified crossover and selection strategies.
  # Manages the process of creating offspring and selecting survivors.
  class GenerationManager
    def initialize(crossover_strategy, selection_strategy, evaluation_function, n_dim, bounds)
      @generation_strategy = create_generation_strategy(
        crossover_strategy, selection_strategy, evaluation_function, n_dim, bounds
      )
    end

    def next_generation(population)
      @generation_strategy.next_generation(population)
    end

    def evaluations_per_generation
      @generation_strategy.evaluations_per_generation
    end

    private

    def create_generation_strategy(crossover_strategy, selection_strategy, evaluation_function, n_dim, bounds)
      if crossover_strategy.is_a?(BlxAlphaCrossover)
        BlxAlphaGenerationStrategy.new(crossover_strategy, selection_strategy, evaluation_function, n_dim, bounds)
      elsif crossover_strategy.is_a?(SimplexCrossover)
        SimplexGenerationStrategy.new(crossover_strategy, selection_strategy, evaluation_function, n_dim, bounds)
      else
        raise Genalgo::StrategyError.new("Unknown crossover strategy: #{crossover_strategy.class}",
                                         context: {
                                           strategy_class: crossover_strategy.class,
                                           available_strategies: %w[BlxAlphaCrossover SimplexCrossover]
                                         })
      end
    end
  end
end
