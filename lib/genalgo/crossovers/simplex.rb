# frozen_string_literal: true

require_relative "../errors"

module Genalgo
  module Crossovers
    # Expands the parental simplex and clamps the sampled child to the bounds.
    class Simplex
      def initialize
        freeze
      end

      def parent_count(dimension)
        dimension + 1
      end

      def call(parents, bounds:, random:)
        validate_parents!(parents, bounds)
        vertices = expand(parents, bounds.dimension)
        offset = sample_offset(vertices, bounds.dimension, random)
        bounds.clamp(Array.new(bounds.dimension) { |coordinate| vertices.last[coordinate] + offset[coordinate] })
      end

      private

      def validate_parents!(parents, bounds)
        return if parents.size == parent_count(bounds.dimension) && parents.all? do |parent|
          bounds.within_bounds?(parent)
        end

        raise StrategyError, "Simplex requires #{parent_count(bounds.dimension)} chromosomes within the same bounds"
      end

      def expand(parents, dimension)
        centroid = parents.transpose.map { |genes| genes.sum.fdiv(genes.size) }
        expansion = Math.sqrt(dimension + 2)
        parents.map do |parent|
          Array.new(dimension) do |coordinate|
            centroid[coordinate] + (expansion * (parent[coordinate] - centroid[coordinate]))
          end
        end
      end

      def sample_offset(vertices, dimension, random)
        offset = Array.new(dimension, 0.0)
        (1..dimension).each do |index|
          factor = random.rand**(1.0 / index)
          update_offset!(offset, vertices[index - 1], vertices[index], factor)
        end
        offset
      end

      def update_offset!(offset, previous, current, factor)
        offset.each_index do |coordinate|
          offset[coordinate] = factor * (previous[coordinate] - current[coordinate] + offset[coordinate])
        end
      end
    end
  end
end
