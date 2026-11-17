# frozen_string_literal: true

require_relative "bounded_chromosome"
require_relative "numeric_validation"

module Genalgo
  # An immutable, evaluated chromosome within shared bounds.
  class Individual
    attr_reader :chromosome, :fitness, :bounds

    def initialize(chromosome:, fitness:)
      raise ArgumentError, "Individual requires a normalized chromosome" unless chromosome.is_a?(BoundedChromosome)
      unless NumericValidation.finite_real?(fitness)
        raise ArgumentError, "Fitness must be a finite real number representable as a Float"
      end

      @bounds = chromosome.bounds
      @chromosome = chromosome.coordinates
      @fitness = fitness.to_f
      freeze
    end
  end
end
