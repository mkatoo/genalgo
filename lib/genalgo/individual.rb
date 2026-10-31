# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # Individual represents a single solution in the genetic algorithm
  # Contains a chromosome (real-valued vector) and fitness value
  # Provides boundary constraint management and validation
  class Individual
    attr_accessor :fitness
    attr_reader :chromosome, :bounds

    def initialize(chromosome: nil, bounds: nil, configuration: nil, random: Random.new, **bound_params)
      @bounds = if configuration
                  configuration.bounds_object
                else
                  bounds || Bounds.new(n_dim: nil, upper_limit: nil, lower_limit: nil, **bound_params)
                end

      if chromosome
        @chromosome = @bounds.within_bounds?(chromosome) ? chromosome : @bounds.clamp_chromosome(chromosome)
      else
        initialize_chromosome(random: random)
      end
    end

    def initialize_chromosome(random:)
      @chromosome = @bounds.random_chromosome(random: random)
    end

    def chromosome=(new_chromosome)
      @chromosome = @bounds.clamp_chromosome(new_chromosome)
    end

    def within_bounds?
      @bounds.within_bounds?(@chromosome)
    end

    def chromosome_within_bounds?(chromosome)
      @bounds.within_bounds?(chromosome)
    end

    def clamp_to_bounds!(chromosome = @chromosome)
      @bounds.clamp_chromosome!(chromosome)
    end

    def clamp_to_bounds(chromosome = @chromosome)
      @bounds.clamp_chromosome(chromosome)
    end

    # Backward compatibility methods
    def n_dim
      @bounds.n_dim
    end

    def upper_limit
      @bounds.upper_limit
    end

    def lower_limit
      @bounds.lower_limit
    end

    private

    def initialize_copy(other)
      super
      @chromosome = other.chromosome.dup
    end
  end
end
