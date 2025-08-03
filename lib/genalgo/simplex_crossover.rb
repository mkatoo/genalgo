# frozen_string_literal: true

module Genalgo
  # Implements Simplex crossover for real-coded genetic algorithms.
  # Uses n_dim+1 parents to create offspring via simplex transformation.
  class SimplexCrossover
    def initialize(n_dim)
      @n_dim = n_dim
    end

    def crossover(parents)
      eps = calculate_epsilon
      mean = calculate_mean_chromosome(parents)
      xs_values = transform_parents(parents, mean, eps)
      cs_values = generate_simplex_coefficients(xs_values)
      create_child(parents, xs_values, cs_values)
    end

    private

    def calculate_epsilon
      Math.sqrt(@n_dim + 2)
    end

    def calculate_mean_chromosome(parents)
      parents.map(&:chromosome).transpose.map { |values| values.sum / values.size }
    end

    def transform_parents(parents, mean, eps)
      parents.map do |parent|
        parent.chromosome.zip(mean).map { |gene, mean_gene| mean_gene + eps * (gene - mean_gene) }
      end
    end

    def generate_simplex_coefficients(xs_values)
      cs_values = Array.new(@n_dim + 1) { Array.new(@n_dim, 0.0) }
      (1..@n_dim).each do |index|
        random_factor = Random.rand**(1.0 / index)
        cs_values[index] = xs_values[index - 1].zip(xs_values[index], cs_values[index - 1]).map do |x_val, y_val, z_val|
          random_factor * (x_val - y_val + z_val)
        end
      end
      cs_values
    end

    def create_child(parents, xs_values, cs_values)
      new_chromosome = xs_values.last.zip(cs_values.last).map { |x_val, y_val| x_val + y_val }
      child = parents.first.dup
      child.chromosome = new_chromosome
      child
    end
  end
end
