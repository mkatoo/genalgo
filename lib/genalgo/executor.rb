# frozen_string_literal: true

require_relative "population"
require_relative "mgg"
require_relative "history"

module Genalgo
  # Executor
  class Executor
    attr_accessor :n_pop, :n_dim, :n_eval, :evaluation_function, :seed, :upper_limit, :lower_limit
    attr_reader :population, :history

    def initialize(params = {})
      @n_pop = params[:n_pop]
      @n_dim = params[:n_dim]
      @n_eval = params[:n_eval]
      @seed = params[:seed] || Random.new_seed
      @evaluation_function = params[:evaluation_function]
      @upper_limit = params[:upper_limit]
      @lower_limit = params[:lower_limit]
    end

    def execute
      setup
      initialize_population
      add_history

      while @evals + MGG.evaluations_per_generation <= @n_eval
        @population = MGG.next_generation(@population)
        @evals += MGG.evaluations_per_generation
        add_history
      end
    end

    def best_individual
      @population.best_individual
    end

    private

    def setup
      Random.srand(@seed)

      MGG.lower_limit = @lower_limit
      MGG.upper_limit = @upper_limit
      MGG.evaluation_function = @evaluation_function
      MGG.crossover = :blx_alpha

      @history = History.new
    end

    def initialize_population
      @population = Population.new(
        n_pop: @n_pop, n_dim: @n_dim, upper_limit: @upper_limit, lower_limit: @lower_limit
      )
      evaluate_population
      @evals = @n_pop
    end

    def evaluate_population
      @population.each do |individual|
        individual.fitness = @evaluation_function.call(individual.chromosome)
      end
    end

    def add_history
      @history.add(@population.best_individual, @evals)
    end
  end
end
