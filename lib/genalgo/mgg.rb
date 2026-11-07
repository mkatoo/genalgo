# frozen_string_literal: true

require_relative "elite_roulette_selection"

module Genalgo
  # One MGG update replaces two parents using their family of two parents and two children.
  class MGG
    CHILDREN_PER_STEP = 2

    def initialize(configuration, evaluator:, random:)
      @bounds = configuration.bounds
      @crossover = configuration.crossover
      @parent_count = @crossover.parent_count(@bounds.dimension)
      @evaluator = evaluator
      @random = random
      @selection = EliteRouletteSelection.new(random: random)
    end

    def step(population)
      raise EvaluationError, "MGG requires a budget for two children" if @evaluator.remaining < CHILDREN_PER_STEP

      indices = population.sample_indices(@parent_count, random: @random)
      chromosomes = indices.map { |index| population[index].chromosome }
      children = evaluate_children(chromosomes)
      replaced = indices.size == 2 ? indices : indices.sample(2, random: @random)
      family = replaced.map { |index| population[index] } + children
      population.replace(replaced, @selection.select(family, 2))
    end

    private

    def evaluate_children(chromosomes)
      sampler = prepare_crossover(chromosomes)
      Array.new(CHILDREN_PER_STEP) do
        @evaluator.evaluate(sampler.call(random: @random))
      end
    end

    def prepare_crossover(chromosomes)
      return @crossover.prepare(chromosomes, bounds: @bounds) if @crossover.respond_to?(:prepare)

      ->(random:) { @crossover.call(chromosomes, bounds: @bounds, random: random) }
    end
  end
end
