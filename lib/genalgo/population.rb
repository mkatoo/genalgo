# frozen_string_literal: true

require_relative "individual"

module Genalgo
  # Population of individuals sharing validated bounds.
  class Population
    include Enumerable

    def initialize(n_pop: nil, bounds: nil, skip_initialization: false, configuration: nil, **bound_params)
      @n_pop = configuration ? configuration.n_pop : n_pop
      @bounds = configuration&.bounds_object || bounds ||
                Bounds.new(n_dim: nil, upper_limit: nil, lower_limit: nil, **bound_params)
      validate_parameters!
      @population = []
      initialize_population unless skip_initialization
    end

    # @param individuals [Array<Genalgo::Individual>]
    def add(individuals)
      @population.concat(individuals)
    end

    # Randomly remove and return the requested number of individuals.
    def pop(size)
      delete sample(size)
    end

    def sample(size)
      @population.sample(size)
    end

    def delete(individuals)
      individuals.each { @population.delete(_1) }
      individuals
    end

    def best_individual
      @population.min_by(&:fitness)
    end

    def validate_parameters!
      return if @n_pop.is_a?(Integer) && @n_pop.positive?

      message = if @n_pop.is_a?(Integer)
                  "Population size (n_pop) must be at least 1, got #{@n_pop}"
                else
                  "Population size (n_pop) must be an integer, got #{@n_pop.class}"
                end
      raise Genalgo::PopulationError.new(message, context: { n_pop: @n_pop, minimum_value: 1 })
    end

    def each(&block)
      @population.each(&block)
    end

    def size
      @population.size
    end

    private

    def initialize_population
      @population = Array.new(@n_pop) { Individual.new(bounds: @bounds) }
    end

    def initialize_copy(other)
      super
      @population = other.map(&:dup)
    end
  end
end
