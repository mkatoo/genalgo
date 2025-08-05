# frozen_string_literal: true

require_relative "individual"

module Genalgo
  # Population
  class Population
    include Enumerable

    def initialize(n_pop:, n_dim:, lower_limit:, upper_limit:, skip_initialization: false)
      @n_pop = n_pop
      @n_dim = n_dim
      @lower_limit = lower_limit
      @upper_limit = upper_limit

      initialize_population unless skip_initialization
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

    def validate_parameters!
      # Population size validation
      raise ArgumentError, "Population size (n_pop) cannot be nil" if @n_pop.nil?
      raise TypeError, "Population size (n_pop) must be an integer, got #{@n_pop.class}" unless @n_pop.is_a?(Integer)
      raise ArgumentError, "Population size (n_pop) must be at least 1, got #{@n_pop}" if @n_pop < 1

      # Dimension validation
      raise ArgumentError, "Dimension (n_dim) cannot be nil" if @n_dim.nil?
      raise TypeError, "Dimension (n_dim) must be an integer, got #{@n_dim.class}" unless @n_dim.is_a?(Integer)
      raise ArgumentError, "Dimension (n_dim) must be at least 1, got #{@n_dim}" if @n_dim < 1

      # Boundary limits validation
      raise ArgumentError, "Lower limit cannot be nil" if @lower_limit.nil?
      raise ArgumentError, "Upper limit cannot be nil" if @upper_limit.nil?
      raise TypeError, "Lower limit must be numeric, got #{@lower_limit.class}" unless @lower_limit.is_a?(Numeric)
      raise TypeError, "Upper limit must be numeric, got #{@upper_limit.class}" unless @upper_limit.is_a?(Numeric)

      return unless @upper_limit <= @lower_limit

      raise ArgumentError,
            "Upper limit (#{@upper_limit}) must be greater than lower limit (#{@lower_limit})"
    end

    def initialize_population
      validate_parameters!

      @population = Array.new(@n_pop) do
        Individual.new(n_dim: @n_dim, lower_limit: @lower_limit, upper_limit: @upper_limit)
      end
    end

    def each(&block)
      @population.each(&block)
    end

    def size
      @population.size
    end

    def dup
      new_pop = Population.new(
        n_pop: @n_pop,
        n_dim: @n_dim,
        lower_limit: @lower_limit,
        upper_limit: @upper_limit,
        skip_initialization: true
      )

      new_pop.instance_variable_set(:@population, @population.map(&:dup))
      new_pop
    end
  end
end
