# frozen_string_literal: true

require_relative "errors"
require_relative "individual"
require_relative "numeric_validation"

module Genalgo
  # Implements elite strategy combined with roulette wheel selection.
  # Preserves the best individual and selects remaining using fitness-proportionate selection.
  class EliteRouletteSelection
    DEFAULT_SCALING_FACTOR = 0.5

    def initialize(random:, scaling_factor: DEFAULT_SCALING_FACTOR)
      unless NumericValidation.finite_real?(scaling_factor) && scaling_factor.to_f.positive?
        raise ConfigurationError, "Scaling factor must be a finite positive real number"
      end

      @random = random
      @scaling_factor = scaling_factor.to_f
    end

    def select(individuals, size)
      validate_selection!(individuals, size)
      return [] if size.zero?

      remaining = individuals.sort_by(&:fitness)
      elite = remaining.shift
      select_non_elite(remaining, size - 1) << elite
    end

    private

    def validate_selection!(individuals, size)
      raise StrategyError, "Selection requires evaluated individuals" unless individuals.all?(Individual)
      return if size.is_a?(Integer) && size.between?(0, individuals.size)

      raise StrategyError, "Selection size must be an integer between 0 and #{individuals.size}"
    end

    def select_non_elite(remaining, count)
      Array.new(count) do
        remaining.delete_at(weighted_index(selection_weights(remaining)))
      end
    end

    # Removing selected individuals preserves ascending fitness order.
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
