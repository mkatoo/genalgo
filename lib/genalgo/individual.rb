# frozen_string_literal: true

module Genalgo
  # Individual
  class Individual
    attr_accessor :fitness, :chromosome

    def initialize(n_dim:, upper_limit:, lower_limit:, chromosome: nil)
      @n_dim = n_dim
      @upper_limit = upper_limit
      @lower_limit = lower_limit
      @chromosome = chromosome
      initialize_chromosome unless @chromosome
    end

    def initialize_chromosome
      @chromosome = Array.new(@n_dim) { Random.rand * (@upper_limit - @lower_limit) + @lower_limit }
    end

    def dup
      copy = Individual.new(
        n_dim: @n_dim,
        upper_limit: @upper_limit,
        lower_limit: @lower_limit,
        chromosome: @chromosome.dup
      )
      copy.fitness = @fitness
      copy
    end
  end
end
