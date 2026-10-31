# frozen_string_literal: true

require_relative "elite_roulette_selection"

module Genalgo
  # Base class for generation strategies in genetic algorithms
  # Defines the interface for different generation approaches
  class GenerationStrategy
    def initialize(configuration, crossover:, random:)
      @random = random
      @crossover_strategy = crossover
      @selection_strategy = EliteRouletteSelection.new(random: random)
      @evaluation_function = configuration.evaluation_function
      @n_dim = configuration.n_dim
    end

    # Abstract method to be implemented by subclasses
    def next_generation(_population)
      raise Genalgo::StrategyError.new("Subclasses must implement next_generation method",
                                       context: { class: self.class, method: "next_generation" })
    end

    # Number of evaluations performed per generation
    def evaluations_per_generation
      2
    end

    protected

    def evaluate_individuals(individuals)
      individuals.each do |individual|
        individual.fitness = @evaluation_function.call(individual.chromosome)
      end
    end
  end
end
