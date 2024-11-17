# frozen_string_literal: true

require_relative "individual"

module Genalgo
  # Minimal Generation Gap (MGG)
  class MGG
    ALPHA = 0.36

    class << self
      attr_accessor :n_dim, :lower_limit, :upper_limit, :evaluation_function, :crossover

      def evaluations_per_generation
        { blx_alpha: 2, simplex: 2 }[crossover]
      end

      def next_generation(population)
        population = population.dup

        if crossover == :blx_alpha
          parent1, parent2 = population.pop(2)
          child1 = blx_alpha(parent1, parent2)
          child2 = blx_alpha(parent1, parent2)
          evaluate_individuals([child1, child2])
          selected_individuals = selection([parent1, parent2, child1, child2], 2)
          population.add(selected_individuals)
        elsif crossover == :simplex
          parents = population.pop(@n_dim + 1)
          child1 = simplex(parents)
          child2 = simplex(parents)
          evaluate_individuals([child1, child2])
          parent1, parent2 = parents.sample(2)
          selected_individuals = parents - [parent1, parent2]
          selected_individuals += selection([parent1, parent2, child1, child2], 2)
          population.add(selected_individuals)
        end

        population
      end

      private

      # BLX-alpha
      # @param parent1 [Genalgo::Individual]
      # @param parent2 [Genalgo::Individual]
      # @return [Genalgo::Individual]
      def blx_alpha(parent1, parent2)
        new_chromosome = parent1.chromosome.zip(parent2.chromosome).map do |x, y|
          x, y = y, x if x > y
          width = y - x
          r_upper = [y + ALPHA * width, @upper_limit].min
          r_lower = [x - ALPHA * width, @lower_limit].max
          Random.rand * (r_upper - r_lower) + r_lower
        end

        child = parent1.dup
        child.chromosome = new_chromosome
        child
      end

      # Simplex
      # @param parents [Array<Genalgo::Individual>]
      # @return [Genalgo::Individual]
      def simplex(parents)
        eps = Math.sqrt(@n_dim + 2)
        mean = parents.map(&:chromosome).transpose.map { |x| x.sum / x.size }
        xs = parents.map do |parent|
          parent.chromosome.zip(mean).map { |x, y| y + eps * (x - y) }
        end
        cs = Array.new(@n_dim + 1) { Array.new(@n_dim, 0.0) }
        (1..@n_dim).each do |i|
          r = Random.rand**(1.0 / i)
          cs[i] = xs[i - 1].zip(xs[i], cs[i - 1]).map { |x, y, z| r * (x - y + z) }
        end
        new_chromosome = xs.last.zip(cs.last).map { |x, y| x + y }
        child = parents.first.dup
        child.chromosome = new_chromosome
        child
      end

      def evaluate_individuals(individuals)
        individuals.each do |individual|
          individual.fitness = evaluation_function.call(individual.chromosome)
        end
      end

      # Elite Strategy
      # @param individuals [Array<Genalgo::Individual>]
      # @param size [Integer]
      # @return [Array<Genalgo::Individual>] selected individuals
      def selection(individuals, size)
        individuals = individuals.sort_by(&:fitness)
        elite = individuals.first
        individuals -= [elite]

        # roulette selection using scaled fitness
        width = individuals.last.fitness - individuals.first.fitness
        width = 1 if width.zero?
        scaled_fitness = individuals.map { |i| width / (i.fitness - individuals.first.fitness + 0.5 * width) }
        total_scaled_fitness = scaled_fitness.sum
        selection_probabilities = scaled_fitness.map { |i| i / total_scaled_fitness }
        selected_individuals = random_choice(size - 1, selection_probabilities).map { |i| individuals[i] }

        selected_individuals + [elite]
      end

      # Random choice with probabilities
      # @param size [Integer] sample size
      # @param probs [Array<Float>] probabilities
      def random_choice(size, probs)
        cumulative_probs = probs.inject([0.0]) { |acc, p| acc << acc.last + p }

        size.times.map do
          r = Random.rand
          cumulative_probs.index { |cp| r <= cp } - 1
        end
      end
    end
  end
end
