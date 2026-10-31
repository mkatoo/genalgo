# frozen_string_literal: true

require_relative "configuration"
require_relative "mutable_configuration"
require_relative "population"
require_relative "mgg"
require_relative "history"

module Genalgo
  # Executor
  class Executor
    attr_reader :population, :history, :configuration, :execution_configuration

    def initialize(params = {})
      @configuration = MutableConfiguration.new(params)
    end

    def execute
      configuration = @configuration.build
      random = Random.new(configuration.seed)
      generation = MGG.new(configuration, random: random)
      setup(configuration)
      initialize_population(configuration, random: random)
      add_history

      evolve(generation, configuration.n_eval)
    end

    def best_individual
      return nil unless @population

      @population.best_individual
    end

    private

    def setup(configuration)
      @execution_configuration = configuration
      @history = History.new
    end

    def evolve(generation, evaluation_budget)
      evaluations_per_generation = generation.evaluations_per_generation
      while @evals + evaluations_per_generation <= evaluation_budget
        @population = generation.next_generation(@population)
        @evals += evaluations_per_generation
        add_history
      end
    end

    def initialize_population(configuration, random:)
      @population = Population.new(n_pop: configuration.n_pop, bounds: configuration.bounds, random: random)
      evaluate_population(configuration.evaluation_function)
      @evals = configuration.n_pop
    end

    def evaluate_population(evaluation_function)
      @population.each do |individual|
        individual.fitness = evaluation_function.call(individual.chromosome)
      end
    end

    def add_history
      @history.add(@population.best_individual, @evals)
    end
  end
end
