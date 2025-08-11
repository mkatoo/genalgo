# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # Individual represents a single solution in the genetic algorithm
  # Contains a chromosome (real-valued vector) and fitness value
  # Provides boundary constraint management and validation
  class Individual
    attr_accessor :fitness
    attr_reader :chromosome, :bounds

    def initialize(n_dim: nil, upper_limit: nil, lower_limit: nil, chromosome: nil, bounds: nil, configuration: nil)
      @bounds = if configuration
                  configuration.bounds_object
                else
                  bounds || Bounds.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)
                end

      if chromosome
        @chromosome = @bounds.within_bounds?(chromosome) ? chromosome : @bounds.clamp_chromosome(chromosome)
      else
        initialize_chromosome
      end
    end

    def initialize_chromosome
      @chromosome = @bounds.random_chromosome
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

    def dup
      copy = Individual.new(bounds: @bounds, chromosome: @chromosome.dup)
      copy.fitness = @fitness
      copy
    end
  end
end
