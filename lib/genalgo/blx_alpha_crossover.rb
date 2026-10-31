# frozen_string_literal: true

module Genalgo
  # Implements BLX-alpha crossover for real-coded genetic algorithms.
  # Creates offspring by blending parent chromosomes with alpha expansion.
  class BlxAlphaCrossover
    DEFAULT_ALPHA = 0.36

    def initialize(random:, alpha: DEFAULT_ALPHA)
      @random = random
      @alpha = alpha
    end

    def crossover(parent1, parent2)
      bounds = parent1.bounds
      coordinates = parent1.chromosome.zip(parent2.chromosome, bounds.lower, bounds.upper)
      new_chromosome = coordinates.map do |x, y, lower, upper|
        blend_genes(x, y, lower, upper)
      end

      child = parent1.dup
      child.chromosome = new_chromosome
      child
    end

    private

    def blend_genes(gene_x, gene_y, lower, upper)
      x_val = [gene_x, gene_y].min
      y_val = [gene_x, gene_y].max

      width = y_val - x_val
      r_upper = [y_val + (@alpha * width), upper].min
      r_lower = [x_val - (@alpha * width), lower].max
      (@random.rand * (r_upper - r_lower)) + r_lower
    end
  end
end
