# frozen_string_literal: true

require_relative "errors"
require_relative "interval_sampling"
require_relative "numeric_validation"

module Genalgo
  # Immutable coordinate intervals shared by every individual in a population.
  class Bounds
    attr_reader :lower, :upper

    def initialize(lower:, upper:)
      validate_arrays!(lower, upper)
      lower.zip(upper).each_with_index { |(low, high), index| validate_interval!(low, high, index) }
      @lower = lower.map(&:to_f).freeze
      @upper = upper.map(&:to_f).freeze
      freeze
    end

    def dimension
      @lower.size
    end

    def within_bounds?(chromosome)
      return false unless chromosome.is_a?(Array) && chromosome.size == dimension

      index = 0
      while index < chromosome.size
        gene = chromosome[index]
        return false unless NumericValidation.finite_real?(gene) && gene.between?(@lower[index], @upper[index])

        index += 1
      end
      true
    end

    def clamp(chromosome)
      unless chromosome.is_a?(Array) && chromosome.size == dimension
        raise ArgumentError, "Chromosome must contain #{dimension} finite real coordinates"
      end

      Array.new(dimension) { |index| clamp_coordinate(chromosome[index], @lower[index], @upper[index]) }
    end

    def sample(random:)
      Array.new(dimension) do |index|
        IntervalSampling.sample(@lower[index], @upper[index], random: random)
      end
    end

    private

    def clamp_coordinate(gene, lower, upper)
      if gene.is_a?(Float) && gene.finite?
        return lower if gene < lower
        return upper if gene > upper

        return gene
      end

      unless NumericValidation.finite_real?(gene)
        raise ArgumentError, "Chromosome must contain #{dimension} finite real coordinates"
      end

      gene.to_f.clamp(lower, upper)
    end

    def validate_arrays!(lower, upper)
      return if lower.is_a?(Array) && upper.is_a?(Array) && !lower.empty? && lower.size == upper.size

      raise ConfigurationError, "Bounds must be non-empty arrays of equal length"
    end

    def validate_interval!(lower, upper, index)
      unless NumericValidation.finite_real?(lower) && NumericValidation.finite_real?(upper)
        raise ConfigurationError.new("Bounds must be finite real numbers", context: { dimension: index })
      end
      return if lower <= upper

      raise ConfigurationError.new("Lower bound exceeds upper bound",
                                   context: { dimension: index, lower: lower, upper: upper })
    end
  end
end
