# frozen_string_literal: true

module Genalgo
  # Implements BLX-alpha crossover for real-coded genetic algorithms.
  # Creates offspring by blending parent chromosomes with alpha expansion.
  class BlxAlphaCrossover
    DEFAULT_ALPHA = 0.36

    def initialize(alpha: DEFAULT_ALPHA)
      @alpha = alpha
    end

    def crossover(parent1, parent2, bounds)
      new_chromosome = parent1.chromosome.zip(parent2.chromosome).map do |x, y|
        blend_genes(x, y, bounds)
      end

      child = parent1.dup
      child.chromosome = new_chromosome
      child
    end

    private

    def blend_genes(gene_x, gene_y, bounds)
      if gene_x > gene_y
        x_val = gene_y
        y_val = gene_x
      else
        x_val = gene_x
        y_val = gene_y
      end

      width = y_val - x_val
      r_upper = [y_val + @alpha * width, bounds[:upper]].min
      r_lower = [x_val - @alpha * width, bounds[:lower]].max
      Random.rand * (r_upper - r_lower) + r_lower
    end
  end
end
