# frozen_string_literal: true

require_relative "generation_strategy"

module Genalgo
  # Generation strategy for BLX-alpha crossover
  # Uses 2 parents and creates 2 children per generation
  class BlxAlphaGenerationStrategy < GenerationStrategy
    def next_generation(population)
      population = population.dup

      parent1, parent2 = population.pop(2)

      child1 = @crossover_strategy.crossover(parent1, parent2, @bounds)
      child2 = @crossover_strategy.crossover(parent1, parent2, @bounds)

      evaluate_individuals([child1, child2])
      selected_individuals = @selection_strategy.select([parent1, parent2, child1, child2], 2)
      population.add(selected_individuals)

      population
    end
  end
end
