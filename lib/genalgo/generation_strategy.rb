# frozen_string_literal: true

module Genalgo
  # Base class for generation strategies in genetic algorithms
  # Defines the interface for different generation approaches
  class GenerationStrategy
    def initialize(crossover_strategy, selection_strategy, evaluation_function, n_dim, bounds)
      @crossover_strategy = crossover_strategy
      @selection_strategy = selection_strategy
      @evaluation_function = evaluation_function
      @n_dim = n_dim
      @bounds = bounds
    end

    # Abstract method to be implemented by subclasses
    def next_generation(population)
      raise NotImplementedError, "Subclasses must implement next_generation method"
    end

    # Number of evaluations performed per generation
    def evaluations_per_generation
      if @crossover_strategy.respond_to?(:evaluations_per_generation)
        @crossover_strategy.evaluations_per_generation
      else
        2
      end
    end

    protected

    def evaluate_individuals(individuals)
      individuals.each do |individual|
        individual.fitness = @evaluation_function.call(individual.chromosome)
      end
    end
  end
end
