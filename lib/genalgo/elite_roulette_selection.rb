# frozen_string_literal: true

require_relative "errors"
require_relative "individual"
require_relative "numeric_validation"

module Genalgo
  # Keeps the elite from an MGG family and selects one other survivor by weighted roulette.
  class EliteRouletteSelection
    DEFAULT_SCALING_FACTOR = 0.5

    def initialize(random:, scaling_factor: DEFAULT_SCALING_FACTOR)
      unless NumericValidation.finite_real?(scaling_factor) && scaling_factor.to_f.positive?
        raise ConfigurationError, "Scaling factor must be a finite positive real number"
      end

      @random = random
      @scaling_factor = scaling_factor.to_f
    end

    def select(family)
      unless family.size == 4 && family.all?(Individual)
        raise StrategyError, "Selection requires four evaluated individuals"
      end

      remaining = family.sort_by(&:fitness)
      elite = remaining.shift
      survivor = remaining.fetch(weighted_index(selection_weights(remaining)))
      [survivor, elite]
    end

    private

    def selection_weights(sorted_individuals)
      normalized = normalized_fitness(sorted_individuals)
      first = normalized.first
      width = normalized.last - first
      return normalized.fill(1.0) if width.zero?

      normalized.map! do |fitness|
        distance = (fitness - first) / width
        @scaling_factor / (distance + @scaling_factor)
      end
    end

    def normalized_fitness(sorted_individuals)
      lowest = sorted_individuals.first.fitness
      highest = sorted_individuals.last.fitness
      # The largest magnitude in a sorted list is at one of its endpoints.
      scale = lowest.abs.clamp(highest.abs, nil)
      return Array.new(sorted_individuals.size, 0.0) if scale.zero?

      sorted_individuals.map { |individual| individual.fitness / scale }
    end

    def weighted_index(weights)
      cumulative = 0.0
      value = @random.rand * weights.sum
      weights.each_with_index do |weight, index|
        cumulative += weight
        return index if value < cumulative
      end
      weights.size - 1
    end
  end
end
