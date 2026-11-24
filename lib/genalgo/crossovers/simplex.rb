# frozen_string_literal: true

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
        expansion = Math.sqrt(bounds.dimension + 2)
        # Transpose creates a fresh array for each coordinate. Expand the vertices there.
        columns = parents.transpose.freeze
        scales = scale_large_columns!(columns, bounds, expansion)
        columns.each { |column| expand_column!(column, expansion) }
        ->(random:) { sample(columns, scales, random) }.freeze
      end

      private

      def sample(columns, scales, random)
        factors = Array.new(columns.size) { |index| random.rand**(1.0 / (index + 1)) }
        child = columns.map { |column| sample_coordinate(column, factors) }
        # The mathematical result can exceed Float even when every parent is finite.
        scales&.each { |index, scale| child[index] = (child[index] * scale).clamp(-Float::MAX, Float::MAX) }
        child
      end

      def scale_large_columns!(columns, bounds, expansion)
        # Leave headroom for the centroid sum, vertex expansion and recursive offsets.
        limit = Float::MAX / (8 * (columns.size + 1) * expansion)
        return if bounds.lower.min >= -limit && bounds.upper.max <= limit

        scales = {}
        columns.each_with_index do |column, index|
          scale = scale_column!(column, limit)
          scales[index] = scale if scale
        end
        scales.freeze
      end

      def scale_column!(column, limit)
        low, high = column.minmax
        scale = [low.abs, high.abs].max.to_f
        return if scale <= limit

        column.map! { |gene| gene.fdiv(scale) }
        scale
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
