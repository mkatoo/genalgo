# frozen_string_literal: true

require_relative "bounds"
require_relative "bounded_chromosome"
require_relative "numeric_validation"

module Genalgo
  # An immutable, evaluated chromosome within shared bounds.
  class Individual
    attr_reader :chromosome, :fitness, :bounds

    def initialize(bounds:, chromosome:, fitness:)
      unless NumericValidation.finite_real?(fitness)
        raise ArgumentError, "Fitness must be a finite real number representable as a Float"
      end

      @bounds = bounds
      @chromosome = immutable_chromosome(chromosome)
      @fitness = fitness.to_f
      freeze
    end

    private

    def immutable_chromosome(chromosome)
      return chromosome.coordinates if chromosome.is_a?(BoundedChromosome) && chromosome.bounds.equal?(bounds)

      raise ArgumentError, "Chromosome must be within bounds" unless bounds.within_bounds?(chromosome)
      return chromosome if chromosome.frozen? && chromosome.all?(Float)

      chromosome.map(&:to_f).freeze
    end
  end
end
