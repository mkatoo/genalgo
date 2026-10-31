# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # A chromosome and its fitness within shared, immutable bounds.
  class Individual
    attr_accessor :fitness
    attr_reader :chromosome, :bounds

    def initialize(bounds:, chromosome:)
      @bounds = bounds
      self.chromosome = chromosome
    end

    def chromosome=(chromosome)
      @chromosome = @bounds.clamp_chromosome(chromosome)
    end

    def within_bounds?
      @bounds.within_bounds?(@chromosome)
    end

    def n_dim
      @bounds.n_dim
    end

    private

    def initialize_copy(other)
      super
      @chromosome = other.chromosome.dup
    end
  end
end
