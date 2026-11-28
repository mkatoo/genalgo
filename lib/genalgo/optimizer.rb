# frozen_string_literal: true

require_relative "configuration"
require_relative "evaluator"
require_relative "population"
require_relative "mgg"
require_relative "result"

module Genalgo
  # Reusable optimizer; all mutable state belongs to a single invocation of run.
  class Optimizer
    attr_reader :configuration

    def initialize(configuration)
      raise ArgumentError, "A Genalgo::Configuration is required" unless configuration.is_a?(Configuration)

      @configuration = configuration
      freeze
    end

    def run(&)
      random = Random.new(configuration.seed)
      evaluator = Evaluator.new(bounds: configuration.bounds,
                                max_evaluations: configuration.max_evaluations, &)
      population = initialize_population(evaluator, random)
      history = [snapshot(population, evaluator)]
      evolve(population, history, evaluator, random)
      Result.new(configuration: configuration, population: population, history: history)
    end

    private

    def initialize_population(evaluator, random)
      bounds = configuration.bounds
      owned = bounds.instance_of?(Bounds)
      individuals = Array.new(configuration.population_size) do
        evaluator.evaluate(bounds.sample(random: random), owned: owned)
      end
      Population.new(individuals)
    end

    def evolve(population, history, evaluator, random)
      generation = MGG.new(configuration, evaluator: evaluator, random: random)
      while evaluator.remaining >= MGG::CHILDREN_PER_STEP
        generation.step(population)
        history << snapshot(population, evaluator)
      end
    end

    def snapshot(population, evaluator)
      Result::Snapshot.new(best_individual: population.best_individual, evaluations: evaluator.evaluations)
    end
  end
end
