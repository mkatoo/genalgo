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

    # Editable settings for the next execution.
    def n_pop
      @configuration.n_pop
    end

    def n_pop=(value)
      @configuration.n_pop = value
    end

    def n_dim
      @configuration.n_dim
    end

    def n_dim=(value)
      @configuration.n_dim = value
    end

    def n_eval
      @configuration.n_eval
    end

    def n_eval=(value)
      @configuration.n_eval = value
    end

    def evaluation_function
      @configuration.evaluation_function
    end

    def evaluation_function=(value)
      @configuration.evaluation_function = value
    end

    def seed
      @configuration.seed
    end

    def seed=(value)
      @configuration.seed = value
    end

    def upper_limit
      @configuration.upper_limit
    end

    def upper_limit=(value)
      @configuration.upper_limit = value
    end

    def lower_limit
      @configuration.lower_limit
    end

    def lower_limit=(value)
      @configuration.lower_limit = value
    end

    def crossover
      @configuration.crossover
    end

    def crossover=(value)
      @configuration.crossover = value
    end

    def execute
      configuration = @configuration.build
      generation = MGG.new(configuration)
      setup(configuration)
      initialize_population(configuration)
      add_history

      evolve(generation, configuration.n_eval)
    end

    def best_individual
      return nil unless @population

      @population.best_individual
    end

    private

    def setup(configuration)
      Random.srand(configuration.seed)
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

    def initialize_population(configuration)
      @population = Population.new(n_pop: configuration.n_pop, bounds: configuration.bounds_object)
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
