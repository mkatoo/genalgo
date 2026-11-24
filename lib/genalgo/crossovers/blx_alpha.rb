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

      # Capture clipped intervals once, then sample independently for each child.
      def prepare(parents, bounds:)
        lower, upper = expanded_intervals(parents, bounds)
        lambda do |random:|
          Array.new(lower.size) { |index| IntervalSampling.sample(lower[index], upper[index], random: random) }
        end.freeze
      end

      private

      def expanded_interval(gene_x, gene_y, lower, upper)
        low = gene_x.to_f
        high = gene_y.to_f
        low, high = high, low if low > high
        expansion = alpha.zero? ? 0.0 : alpha * (high - low)
        low -= expansion
        high += expansion
        low = lower if low < lower
        high = upper if high > upper
        yield low, high
      end

      def expanded_intervals(parents, bounds)
        first, last = parents
        lower = Array.new(bounds.dimension)
        upper = Array.new(lower.size)
        lower.each_index do |index|
          expanded_interval(first[index], last[index], bounds.lower[index], bounds.upper[index]) do |low, high|
            lower[index] = low
            upper[index] = high
          end
        end
        [lower, upper]
      end
    end
  end
end
