# frozen_string_literal: true

require_relative "../errors"
require_relative "../interval_sampling"
require_relative "../numeric_validation"

module Genalgo
  module Crossovers
    # Samples the expanded parental interval after clipping it to the bounds.
    class BlxAlpha
      attr_reader :alpha

      def initialize(alpha: 0.36)
        unless NumericValidation.finite_real?(alpha) && alpha >= 0
          raise ConfigurationError, "Alpha must be a finite non-negative real number"
        end

        @alpha = alpha.to_f
        freeze
      end

      def parent_count(_dimension)
        2
      end

      def call(parents, bounds:, random:)
        prepare(parents, bounds: bounds).call(random: random)
      end

      # Capture clipped intervals once, then sample independently for each child.
      def prepare(parents, bounds:)
        validate_parents!(parents, bounds)
        intervals = expanded_intervals(parents, bounds)
        ->(random:) { intervals.map { |low, high| IntervalSampling.sample(low, high, random: random) } }.freeze
      end

      private

      def validate_parents!(parents, bounds)
        unless parents.size == parent_count(bounds.dimension) && parents.all? { |parent| bounds.within_bounds?(parent) }
          raise StrategyError, "BLX-alpha requires two chromosomes within the same bounds"
        end
      end

      def expanded_interval(gene_x, gene_y, lower, upper)
        low, high = [gene_x, gene_y].minmax
        expansion = alpha.zero? ? 0.0 : alpha * (high - low)
        low = [low - expansion, lower].max
        high = [high + expansion, upper].min
        [low, high]
      end

      def expanded_intervals(parents, bounds)
        first, last = parents
        Array.new(bounds.dimension) do |index|
          expanded_interval(first[index].to_f, last[index].to_f, bounds.lower[index], bounds.upper[index])
        end
      end
    end
  end
end
