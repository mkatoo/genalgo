# frozen_string_literal: true

module Genalgo
  # Individual
  class Individual
    attr_accessor :fitness, :chromosome

    def initialize(n_dim:, upper_limit:, lower_limit:, seed:, chromosome: nil)
      @n_dim = n_dim
      @upper_limit = upper_limit
      @lower_limit = lower_limit
      @alpha = 0.36
      @seed = seed
      @chromosome = chromosome
      initialize_chromosome unless @chromosome
    end

    def initialize_chromosome
      @chromosome = Array.new(@n_dim) { Random.rand * (@upper_limit - @lower_limit) + @lower_limit }
    end

    # BLX-alpha
    # @param other [Genalgo::Individual]
    # @return [Genalgo::Individual]
    def crossover(other)
      new_chromosome = @chromosome.zip(other.chromosome).map do |x, y|
        x, y = y, x if x > y
        width = y - x
        r_upper = [y + @alpha * width, @upper_limit].min
        r_lower = [x - @alpha * width, @lower_limit].max
        Random.rand * (r_upper - r_lower) + r_lower
      end

      Individual.new(
        n_dim: @n_dim, upper_limit: @upper_limit, lower_limit: @lower_limit, seed: @seed, chromosome: new_chromosome
      )
    end
  end
end
