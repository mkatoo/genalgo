# frozen_string_literal: true

require_relative "configuration"
require_relative "mutable_configuration"
require_relative "population"
require_relative "mgg"
require_relative "history"

module Genalgo
  # Executor
  class Executor
    attr_reader :population, :history, :configuration

    def initialize(params = {})
      if params.is_a?(Configuration)
        @configuration = params
      else
        @configuration = MutableConfiguration.new(params)
      end
    end

    # Backward compatibility: delegate attribute access to configuration
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
      @configuration.validate_before_execution!
      setup
      initialize_population
      add_history

      while @evals + MGG.evaluations_per_generation(@configuration) <= @configuration.n_eval
        @population = MGG.next_generation(@population, @configuration)
        @evals += MGG.evaluations_per_generation(@configuration)
        add_history
      end
    end

    def best_individual
      return nil unless @population

      @population.best_individual
    end

    private

    def setup
      Random.srand(@configuration.seed)

      # Set MGG attributes for backward compatibility
      MGG.lower_limit = @configuration.lower_limit
      MGG.upper_limit = @configuration.upper_limit
      MGG.evaluation_function = @configuration.evaluation_function
      MGG.n_dim = @configuration.n_dim
      MGG.crossover = @configuration.crossover

      @history = History.new
    end

    def initialize_population
      @population = Population.new(configuration: @configuration)
      evaluate_population
      @evals = @configuration.n_pop
    end

    def evaluate_population
      @population.each do |individual|
        individual.fitness = @configuration.evaluation_function.call(individual.chromosome)
      end
    end

    def add_history
      @history.add(@population.best_individual, @evals)
    end
  end
end
