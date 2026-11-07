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

      sorted_individuals = individuals.sort_by(&:fitness)
      elite = sorted_individuals.first
      remaining_individuals = sorted_individuals[1..]

      return [elite] if size == 1

      non_elite_selected = select_non_elite(remaining_individuals, size - 1)
      non_elite_selected + [elite]
    end

    private

    def validate_selection!(individuals, size)
      raise StrategyError, "Selection requires evaluated individuals" unless individuals.all?(Individual)
      return if size.is_a?(Integer) && size.between?(0, individuals.size)

      raise StrategyError, "Selection size must be an integer between 0 and #{individuals.size}"
    end

    def select_non_elite(sorted_individuals, count)
      remaining = sorted_individuals.dup
      Array.new(count) do
        remaining.delete_at(weighted_index(selection_weights(remaining)))
      end
    end

    # Removing selected individuals preserves ascending fitness order.
    def selection_weights(sorted_individuals)
      normalized = normalized_fitness(sorted_individuals)
      width = normalized.last - normalized.first
      return Array.new(sorted_individuals.size, 1.0) if width.zero?

      normalized.map { |fitness| @scaling_factor / (((fitness - normalized.first) / width) + @scaling_factor) }
    end

    def normalized_fitness(individuals)
      scale = individuals.map { |individual| individual.fitness.abs }.max
      individuals.map { |individual| scale.zero? ? 0.0 : individual.fitness / scale }
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
