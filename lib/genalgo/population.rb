# frozen_string_literal: true

require_relative "individual"

module Genalgo
  # Population
  class Population
    include Enumerable

    def initialize(n_pop: nil, n_dim: nil, lower_limit: nil, upper_limit: nil, skip_initialization: false,
                   configuration: nil)
      if configuration
        @configuration = configuration
        @n_pop = configuration.n_pop
        @n_dim = configuration.n_dim
        @lower_limit = configuration.lower_limit
        @upper_limit = configuration.upper_limit
      else
        # Legacy initialization for backward compatibility
        @n_pop = n_pop
        @n_dim = n_dim
        @lower_limit = lower_limit
        @upper_limit = upper_limit
      end

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
      validate_population_size!
      validate_dimension!
      validate_boundary_limits!
    end

    def each(&block)
      @population.each(&block)
    end

    def size
      @population.size
    end

    def dup
      new_pop = if @configuration
                  Population.new(
                    configuration: @configuration,
                    skip_initialization: true
                  )
                else
                  Population.new(
                    n_pop: @n_pop,
                    n_dim: @n_dim,
                    lower_limit: @lower_limit,
                    upper_limit: @upper_limit,
                    skip_initialization: true
                  )
                end

      new_pop.set_population(@population.map(&:dup))
      new_pop
    end

    protected

    def set_population(population_array)
      @population = population_array
    end

    def initialize_population
      validate_parameters! unless @configuration

      @population = Array.new(@n_pop) do
        if @configuration
          Individual.new(configuration: @configuration)
        else
          Individual.new(n_dim: @n_dim, lower_limit: @lower_limit, upper_limit: @upper_limit)
        end
      end
    end

    def validate_population_size!
      if @n_pop.nil?
        raise Genalgo::PopulationError.new("Population size (n_pop) cannot be nil",
                                           context: { n_pop: @n_pop })
      end

      unless @n_pop.is_a?(Integer)
        raise Genalgo::PopulationError.new("Population size (n_pop) must be an integer, got #{@n_pop.class}",
                                           context: { n_pop: @n_pop, expected_type: "Integer" })
      end

      return unless @n_pop < 1

      raise Genalgo::PopulationError.new("Population size (n_pop) must be at least 1, got #{@n_pop}",
                                         context: { n_pop: @n_pop, minimum_value: 1 })
    end

    def validate_dimension!
      if @n_dim.nil?
        raise Genalgo::ConfigurationError.new("Dimension (n_dim) cannot be nil",
                                              context: { n_dim: @n_dim })
      end

      unless @n_dim.is_a?(Integer)
        raise Genalgo::ConfigurationError.new("Dimension (n_dim) must be an integer, got #{@n_dim.class}",
                                              context: { n_dim: @n_dim, expected_type: "Integer" })
      end

      return unless @n_dim < 1

      raise Genalgo::ConfigurationError.new("Dimension (n_dim) must be at least 1, got #{@n_dim}",
                                            context: { n_dim: @n_dim, minimum_value: 1 })
    end

    def validate_boundary_limits!
      if @lower_limit.nil?
        raise Genalgo::ConfigurationError.new("Lower limit cannot be nil",
                                              context: { lower_limit: @lower_limit })
      end
      if @upper_limit.nil?
        raise Genalgo::ConfigurationError.new("Upper limit cannot be nil",
                                              context: { upper_limit: @upper_limit })
      end
      unless @lower_limit.is_a?(Numeric)
        raise Genalgo::ConfigurationError.new("Lower limit must be numeric, got #{@lower_limit.class}",
                                              context: { lower_limit: @lower_limit, expected_type: "Numeric" })
      end
      unless @upper_limit.is_a?(Numeric)
        raise Genalgo::ConfigurationError.new("Upper limit must be numeric, got #{@upper_limit.class}",
                                              context: { upper_limit: @upper_limit, expected_type: "Numeric" })
      end

      return unless @upper_limit <= @lower_limit

      raise Genalgo::ConfigurationError.new(
        "Upper limit (#{@upper_limit}) must be greater than lower limit (#{@lower_limit})",
        context: { upper_limit: @upper_limit, lower_limit: @lower_limit }
      )
    end
  end
end
