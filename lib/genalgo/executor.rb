# frozen_string_literal: true

require_relative "population"

module Genalgo
  # Executor
  class Executor
    attr_accessor :n_pop, :n_dim, :n_eval, :evaluation_function, :seed, :upper_limit, :lower_limit

    attr_reader :population

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
      Random.srand(@seed)
      initialize_population

      while @_evals + 2 <= @n_eval
        parent1, parent2 = @population.pop(2)

        child1 = parent1.crossover(parent2)
        child2 = parent1.crossover(parent2)

        evaluate_individuals([child1, child2])
        @_evals += 2

        selected_individuals = selection([parent1, parent2, child1, child2], 2)

        @population.add(selected_individuals)
      end
    end

    def best_individual
      @population.best_individual
    end

    private

    def initialize_population
      @population = Population.new(
        n_pop: @n_pop, n_dim: @n_dim, upper_limit: @upper_limit, lower_limit: @lower_limit, seed: @seed
      )
      evaluate_population
      @_evals = @n_pop
    end

    def evaluate_population
      @population.each do |individual|
        individual.fitness = @evaluation_function.call(individual.chromosome)
      end
    end

    def evaluate_individuals(individuals)
      individuals.each do |individual|
        individual.fitness = @evaluation_function.call(individual.chromosome)
      end
    end

    # Elite Strategy
    # @param individuals [Array<Genalgo::Individual>]
    # @param size [Integer]
    # @return [Array<Genalgo::Individual>] selected individuals
    def selection(individuals, size)
      individuals = individuals.sort_by(&:fitness)
      elite = individuals.first
      individuals -= [elite]

      # roulette selection using scaled fitness
      width = individuals.last.fitness - individuals.first.fitness
      width = 1 if width.zero?
      scaled_fitness = individuals.map { |i| width / (i.fitness - individuals.first.fitness + 0.5 * width) }
      total_scaled_fitness = scaled_fitness.sum
      selection_probabilities = scaled_fitness.map { |i| i / total_scaled_fitness }
      selected_individuals = random_choice(size - 1, selection_probabilities).map { |i| individuals[i] }

      selected_individuals + [elite]
    end

    def random_choice(size, probs)
      cumulative_probs = probs.inject([0.0]) { |acc, p| acc << acc.last + p }

      size.times.map do
        r = Random.rand
        cumulative_probs.index { |cp| r <= cp } - 1
      end
    end
  end
end
