# frozen_string_literal: true

module Genalgo
  # Implements Simplex crossover for real-coded genetic algorithms.
  # Uses n_dim+1 parents to create offspring via simplex transformation.
  class SimplexCrossover
    def initialize(random:)
      @random = random
    end

    def crossover(parents)
      raise StrategyError, "Simplex requires at least two parents" if parents.empty?

      n_dim = parents.first.n_dim
      raise StrategyError, "Simplex requires #{n_dim + 1} parents" unless parents.size == n_dim + 1

      eps = Math.sqrt(n_dim + 2)
      mean = calculate_mean_chromosome(parents)
      xs_values = transform_parents(parents, mean, eps)
      cs_values = generate_simplex_coefficients(xs_values, n_dim)
      create_child(parents, xs_values, cs_values)
    end

    private

    def calculate_mean_chromosome(parents)
      parents.map(&:chromosome).transpose.map { |values| values.sum / values.size }
    end

    def transform_parents(parents, mean, eps)
      parents.map do |parent|
        parent.chromosome.zip(mean).map { |gene, mean_gene| mean_gene + (eps * (gene - mean_gene)) }
      end
    end

    def generate_simplex_coefficients(xs_values, n_dim)
      cs_values = Array.new(n_dim + 1) { Array.new(n_dim, 0.0) }

      (1..n_dim).each do |index|
        cs_values[index] = calculate_coefficient_for_dimension(xs_values, cs_values, index)
      end

      cs_values
    end

    def calculate_coefficient_for_dimension(xs_values, cs_values, index)
      random_factor = @random.rand**(1.0 / index)

      xs_values[index - 1].zip(xs_values[index], cs_values[index - 1]).map do |x_val, y_val, z_val|
        random_factor * (x_val - y_val + z_val)
      end
    end

    def create_child(parents, xs_values, cs_values)
      new_chromosome = xs_values.last.zip(cs_values.last).map { |x_val, y_val| x_val + y_val }
      child = parents.first.dup
      child.chromosome = new_chromosome
      child
    end
  end
end
