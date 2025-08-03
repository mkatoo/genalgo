# frozen_string_literal: true

require_relative "blx_alpha_crossover"
require_relative "simplex_crossover"
require_relative "elite_roulette_selection"

module Genalgo
  # Orchestrates generation evolution using specified crossover and selection strategies.
  # Manages the process of creating offspring and selecting survivors.
  class GenerationManager
    def initialize(crossover_strategy, selection_strategy, evaluation_function, n_dim, bounds)
      @crossover_strategy = crossover_strategy
      @selection_strategy = selection_strategy
      @evaluation_function = evaluation_function
      @n_dim = n_dim
      @bounds = bounds
    end

    def next_generation(population)
      population = population.dup

      if @crossover_strategy.is_a?(BlxAlphaCrossover)
        handle_blx_alpha_generation(population)
      elsif @crossover_strategy.is_a?(SimplexCrossover)
        handle_simplex_generation(population)
      else
        raise ArgumentError, "Unknown crossover strategy: #{@crossover_strategy.class}"
      end

      population
    end

    def evaluations_per_generation
      2 # Both strategies create 2 children per generation
    end

    private

    def handle_blx_alpha_generation(population)
      parent1, parent2 = population.pop(2)

      child1 = @crossover_strategy.crossover(parent1, parent2, @bounds)
      child2 = @crossover_strategy.crossover(parent1, parent2, @bounds)

      evaluate_individuals([child1, child2])
      selected_individuals = @selection_strategy.select([parent1, parent2, child1, child2], 2)
      population.add(selected_individuals)
    end

    def handle_simplex_generation(population)
      parents = population.pop(@n_dim + 1)

      child1 = @crossover_strategy.crossover(parents)
      child2 = @crossover_strategy.crossover(parents)

      evaluate_individuals([child1, child2])
      parent1, parent2 = parents.sample(2)
      selected_individuals = parents - [parent1, parent2]
      selected_individuals += @selection_strategy.select([parent1, parent2, child1, child2], 2)
      population.add(selected_individuals)
    end

    def evaluate_individuals(individuals)
      individuals.each do |individual|
        individual.fitness = @evaluation_function.call(individual.chromosome)
      end
    end
  end
end
