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
      return false unless valid_chromosome?(chromosome)

      chromosome.each_with_index.all? { |gene, index| gene.between?(@lower[index], @upper[index]) }
    end

    def clamp(chromosome)
      unless valid_chromosome?(chromosome)
        raise ArgumentError, "Chromosome must contain #{dimension} finite real coordinates"
      end

      chromosome.each_with_index.map { |gene, index| gene.to_f.clamp(@lower[index], @upper[index]) }
    end

    def sample(random:)
      Array.new(dimension) do |index|
        IntervalSampling.sample(@lower[index], @upper[index], random: random)
      end
    end

    private

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

    def valid_chromosome?(chromosome)
      chromosome.is_a?(Array) && chromosome.size == dimension && chromosome.all? do |gene|
        NumericValidation.finite_real?(gene)
      end
    end
  end
end
