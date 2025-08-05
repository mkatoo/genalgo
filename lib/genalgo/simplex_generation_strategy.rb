# frozen_string_literal: true

require_relative "generation_strategy"

module Genalgo
  # Generation strategy for Simplex crossover
  # Uses n_dim + 1 parents and creates 2 children per generation
  class SimplexGenerationStrategy < GenerationStrategy
    def next_generation(population)
      population = population.dup

      parents = population.pop(@n_dim + 1)

      child1 = @crossover_strategy.crossover(parents)
      child2 = @crossover_strategy.crossover(parents)

      evaluate_individuals([child1, child2])
      parent1, parent2 = parents.sample(2)
      selected_individuals = parents - [parent1, parent2]
      selected_individuals += @selection_strategy.select([parent1, parent2, child1, child2], 2)
      population.add(selected_individuals)

      population
    end
  end
end
