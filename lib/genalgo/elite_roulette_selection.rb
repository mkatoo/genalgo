# frozen_string_literal: true

module Genalgo
  # Implements elite strategy combined with roulette wheel selection.
  # Preserves the best individual and selects remaining using fitness-proportionate selection.
  class EliteRouletteSelection
    DEFAULT_SCALING_FACTOR = 0.5

    def initialize(scaling_factor: DEFAULT_SCALING_FACTOR)
      @scaling_factor = scaling_factor
    end

    def select(individuals, size)
      sorted_individuals = individuals.sort_by(&:fitness)
      elite = sorted_individuals.first
      remaining_individuals = sorted_individuals[1..]

      return [elite] if size == 1

      non_elite_selected = select_non_elite(remaining_individuals, size - 1)
      non_elite_selected + [elite]
    end

    private

    def select_non_elite(individuals, count)
      return [] if count.zero? || individuals.empty?

      scaled_fitness = calculate_scaled_fitness(individuals)
      selection_probabilities = calculate_probabilities(scaled_fitness)
      random_choice(count, selection_probabilities).map { |i| individuals[i] }
    end

    def calculate_scaled_fitness(individuals)
      width = individuals.last.fitness - individuals.first.fitness
      width = 1 if width.zero?

      individuals.map do |individual|
        width / (individual.fitness - individuals.first.fitness + @scaling_factor * width)
      end
    end

    def calculate_probabilities(scaled_fitness)
      total = scaled_fitness.sum
      scaled_fitness.map { |fitness| fitness / total }
    end

    def random_choice(size, probs)
      cumulative_probs = probs.inject([0.0]) { |acc, p| acc << acc.last + p }

      size.times.map do
        r = Random.rand
        cumulative_probs.index { |cp| r <= cp } - 1
      end
    end
  end
end
