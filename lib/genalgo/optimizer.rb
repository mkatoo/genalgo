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
      Result.new(configuration: configuration, population: population, history: history,
                 evaluations: evaluator.evaluations)
    end

    private

    # This run evaluates every parent using the same bounds before handing it to MGG.
    def prepare_normalized_parents?
      return false unless configuration.bounds.instance_of?(Bounds)

      crossover = configuration.crossover
      crossover.respond_to?(:instance_of?) &&
        (crossover.instance_of?(Crossovers::BlxAlpha) || crossover.instance_of?(Crossovers::Simplex))
    end

    def initialize_population(evaluator, random)
      individuals = Array.new(configuration.population_size) do
        evaluator.evaluate(configuration.bounds.sample(random: random))
      end
      Population.new(individuals)
    end

    def evolve(population, history, evaluator, random)
      generation = MGG.new(configuration, evaluator: evaluator, random: random,
                                          prepare_normalized: prepare_normalized_parents?)
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
