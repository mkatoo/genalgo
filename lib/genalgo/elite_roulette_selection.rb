# frozen_string_literal: true

require_relative "errors"
require_relative "individual"

module Genalgo
  # Implements elite strategy combined with roulette wheel selection.
  # Preserves the best individual and selects remaining using fitness-proportionate selection.
  class EliteRouletteSelection
    DEFAULT_SCALING_FACTOR = 0.5

    def initialize(random:, scaling_factor: DEFAULT_SCALING_FACTOR)
      unless scaling_factor.is_a?(Numeric) && scaling_factor.real? && scaling_factor.finite? &&
             scaling_factor.abs <= Float::MAX && scaling_factor.to_f.positive?
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
      unless individuals.all? { |individual| individual.is_a?(Individual) }
        raise StrategyError, "Selection requires evaluated individuals"
      end
      return if size.is_a?(Integer) && size.between?(0, individuals.size)

      raise StrategyError, "Selection size must be an integer between 0 and #{individuals.size}"
    end

    def select_non_elite(individuals, count)
      remaining = individuals.dup
      Array.new(count) do
        probabilities = calculate_probabilities(calculate_scaled_fitness(remaining))
        remaining.delete_at(random_choice(probabilities))
      end
    end

    def calculate_scaled_fitness(individuals)
      normalized = normalized_fitness(individuals)
      width = normalized.last - normalized.first
      return Array.new(individuals.size, 1.0) if width.zero?

      normalized.map { |fitness| @scaling_factor / (((fitness - normalized.first) / width) + @scaling_factor) }
    end

    def normalized_fitness(individuals)
      scale = individuals.map { |individual| individual.fitness.abs }.max
      individuals.map { |individual| scale.zero? ? 0.0 : individual.fitness / scale }
    end

    def calculate_probabilities(scaled_fitness)
      total = scaled_fitness.sum
      scaled_fitness.map { |fitness| fitness / total }
    end

    def random_choice(probabilities)
      cumulative = 0.0
      value = @random.rand
      probabilities.each_with_index do |probability, index|
        cumulative += probability
        return index if value < cumulative
      end
      probabilities.size - 1
    end
  end
end
