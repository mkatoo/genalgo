# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # An immutable, evaluated chromosome within shared bounds.
  class Individual
    attr_reader :chromosome, :fitness, :bounds

    def initialize(bounds:, chromosome:, fitness:)
      unless fitness.is_a?(Numeric) && fitness.real? && fitness.finite? && fitness.abs <= Float::MAX
        raise ArgumentError, "Fitness must be a finite real number representable as a Float"
      end
      raise ArgumentError, "Chromosome must be within bounds" unless bounds.within_bounds?(chromosome)

      @bounds = bounds
      @chromosome = chromosome.map(&:to_f).freeze
      @fitness = fitness.to_f
      freeze
    end
  end
end
