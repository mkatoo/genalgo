# frozen_string_literal: true

module Genalgo
  # Bounds class manages the boundary constraints for genetic algorithm individuals
  # Provides validation, clamping, and chromosome generation within specified limits
  class Bounds
    attr_reader :n_dim, :upper_limit, :lower_limit

    def initialize(n_dim:, upper_limit:, lower_limit:)
      validate_parameters!(n_dim, upper_limit, lower_limit)

      @n_dim = n_dim
      @upper_limit = upper_limit
      @lower_limit = lower_limit
    end

    def within_bounds?(chromosome)
      return false unless chromosome
      return false unless chromosome.size == @n_dim

      chromosome.all? { |gene| gene >= @lower_limit && gene <= @upper_limit }
    end

    def clamp_chromosome!(chromosome)
      chromosome.map! { |gene| gene.clamp(@lower_limit, @upper_limit) }
    end

    def clamp_chromosome(chromosome)
      chromosome.map { |gene| gene.clamp(@lower_limit, @upper_limit) }
    end

    def random_chromosome
      Array.new(@n_dim) { (Random.rand * (@upper_limit - @lower_limit)) + @lower_limit }
    end

    private

    def validate_parameters!(n_dim, upper_limit, lower_limit)
      validate_dimension!(n_dim)
      validate_limits!(upper_limit, lower_limit)
    end

    def validate_dimension!(n_dim)
      if n_dim.nil?
        raise Genalgo::ConfigurationError.new("Dimension (n_dim) cannot be nil",
                                              context: { n_dim: n_dim })
      end

      unless n_dim.is_a?(Integer)
        raise Genalgo::ConfigurationError.new("Dimension (n_dim) must be an integer, got #{n_dim.class}",
                                              context: { n_dim: n_dim, expected_type: "Integer" })
      end

      return unless n_dim < 1

      raise Genalgo::ConfigurationError.new("Dimension (n_dim) must be at least 1, got #{n_dim}",
                                            context: { n_dim: n_dim, minimum_value: 1 })
    end

    def validate_limits!(upper_limit, lower_limit)
      validate_limit_values!(upper_limit, lower_limit)
      validate_limit_order!(upper_limit, lower_limit)
    end

    def validate_limit_values!(upper_limit, lower_limit)
      if lower_limit.nil?
        raise Genalgo::ConfigurationError.new("Lower limit cannot be nil",
                                              context: { lower_limit: lower_limit })
      end
      if upper_limit.nil?
        raise Genalgo::ConfigurationError.new("Upper limit cannot be nil",
                                              context: { upper_limit: upper_limit })
      end
      unless lower_limit.is_a?(Numeric)
        raise Genalgo::ConfigurationError.new("Lower limit must be numeric, got #{lower_limit.class}",
                                              context: { lower_limit: lower_limit, expected_type: "Numeric" })
      end
      return if upper_limit.is_a?(Numeric)

      raise Genalgo::ConfigurationError.new("Upper limit must be numeric, got #{upper_limit.class}",
                                            context: { upper_limit: upper_limit, expected_type: "Numeric" })
    end

    def validate_limit_order!(upper_limit, lower_limit)
      return unless upper_limit < lower_limit

      raise Genalgo::ConfigurationError.new(
        "Upper limit (#{upper_limit}) must be greater than or equal to lower limit (#{lower_limit})",
        context: { upper_limit: upper_limit, lower_limit: lower_limit }
      )
    end
  end
end
