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
        bounds.clamp(vertices.last.zip(offset).map { |vertex, delta| vertex + delta })
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
          parent.zip(centroid).map { |gene, mean| mean + (expansion * (gene - mean)) }
        end
      end

      def sample_offset(vertices, dimension, random)
        offset = Array.new(dimension, 0.0)
        (1..dimension).each do |index|
          factor = random.rand**(1.0 / index)
          offset = vertices[index - 1].zip(vertices[index], offset).map do |previous, current, delta|
            factor * (previous - current + delta)
          end
        end
        offset
      end
    end
  end
end
