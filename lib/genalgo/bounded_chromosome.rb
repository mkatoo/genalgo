# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # Internal proof that coordinates were copied, clamped, converted to Float, and frozen.
  class BoundedChromosome
    attr_reader :bounds, :coordinates

    def initialize(bounds:, chromosome:)
      @bounds = bounds
      @coordinates = bounds.clamp(chromosome).freeze
      freeze
    end
  end

  private_constant :BoundedChromosome
end
