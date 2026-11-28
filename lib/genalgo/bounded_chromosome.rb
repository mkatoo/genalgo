# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # Internal proof that coordinates are owned, clamped, converted to Float, and frozen.
  class BoundedChromosome
    attr_reader :bounds, :coordinates

    def initialize(bounds:, chromosome:, owned: false)
      @bounds = bounds
      normalized = owned ? bounds.clamp_owned!(chromosome) : bounds.clamp(chromosome)
      @coordinates = normalized.freeze
      freeze
    end
  end

  private_constant :BoundedChromosome
end
