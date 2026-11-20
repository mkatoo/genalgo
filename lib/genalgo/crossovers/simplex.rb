# frozen_string_literal: true

require_relative "../errors"

module Genalgo
  module Crossovers
    # Expands the parental simplex and samples candidate coordinates before normalization.
    class Simplex
      def initialize
        freeze
      end

      def parent_count(dimension)
        dimension + 1
      end

      # Capture the expanded simplex once, then sample independently for each child.
      def prepare(parents, bounds:)
        validate_parents!(parents, bounds)
        prepare_normalized(parents, bounds: bounds)
      end

      private

      def prepare_normalized(parents, bounds:)
        expansion = Math.sqrt(bounds.dimension + 2)
        # Transpose creates a fresh array for each coordinate. Expand the vertices there.
        columns = parents.transpose.each { |column| expand_column!(column, expansion) }.freeze
        ->(random:) { sample(columns, random) }.freeze
      end

      def sample(columns, random)
        factors = Array.new(columns.size) { |index| random.rand**(1.0 / (index + 1)) }
        columns.map { |column| sample_coordinate(column, factors) }
      end

      def validate_parents!(parents, bounds)
        return if parents.size == parent_count(bounds.dimension) && parents.all? do |parent|
          bounds.within_bounds?(parent)
        end

        raise StrategyError, "Simplex requires #{parent_count(bounds.dimension)} chromosomes within the same bounds"
      end

      def expand_column!(column, expansion)
        size = column.size
        centroid = column.sum.fdiv(size)
        index = 0
        while index < size
          column[index] = centroid + (expansion * (column[index] - centroid))
          index += 1
        end
        column.freeze
      end

      def sample_coordinate(column, factors)
        offset = 0.0
        size = factors.size
        index = 0
        while index < size
          offset = factors[index] * (column[index] - column[index + 1] + offset)
          index += 1
        end
        column.last + offset
      end
    end
  end
end
