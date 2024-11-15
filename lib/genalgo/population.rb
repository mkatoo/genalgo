# frozen_string_literal: true

require_relative "individual"

module Genalgo
  # Population
  class Population
    include Enumerable

    def initialize(n_pop:, n_dim:, lower_limit:, upper_limit:)
      @n_pop = n_pop
      @n_dim = n_dim
      @lower_limit = lower_limit
      @upper_limit = upper_limit

      initialize_population
    end

    # Add individuals to population
    # @param individuals [Array<Genalgo::Individual>]
    def add(individuals)
      @population.concat(individuals)
    end

    # Delete individuals from population randomly
    # @param size [Integer] sample size
    # @return [Array<Genalgo::Individual>] deleted individuals
    def pop(size)
      delete sample(size)
    end

    # Sample individuals from population
    # @param size [Integer] sample size
    # @return [Array<Genalgo::Individual>] sampled individuals
    def sample(size)
      @population.sample(size)
    end

    # Delete individuals from population
    # @param individuals [Array<Genalgo::Individual>] individuals to be deleted
    # @return [Array<Genalgo::Individual>] deleted individuals
    def delete(individuals)
      individuals.each { @population.delete(_1) }
      individuals
    end

    def best_individual
      @population.min_by(&:fitness)
    end

    def initialize_population
      raise "Population size is not enough." if @n_pop <= 0
      raise "Dimension is not enough." if @n_dim <= 0

      @population = Array.new(@n_pop) do
        Individual.new(n_dim: @n_dim, lower_limit: @lower_limit, upper_limit: @upper_limit)
      end
    end

    def each(&block)
      @population.each(&block)
    end
  end
end
