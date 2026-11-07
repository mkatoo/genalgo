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
        unless parents.size == parent_count(bounds.dimension) && parents.all? { |parent| bounds.within_bounds?(parent) }
          raise StrategyError, "BLX-alpha requires two chromosomes within the same bounds"
        end

        parents.first.zip(parents.last, bounds.lower, bounds.upper).map do |x, y, lower, upper|
          blend(x.to_f, y.to_f, lower, upper, random)
        end
      end

      private

      def blend(gene_x, gene_y, lower, upper, random)
        low, high = [gene_x, gene_y].minmax
        expansion = alpha.zero? ? 0.0 : alpha * (high - low)
        low = [low - expansion, lower].max
        high = [high + expansion, upper].min
        IntervalSampling.sample(low, high, random: random)
      end
    end
  end
end
