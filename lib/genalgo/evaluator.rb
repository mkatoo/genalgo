# frozen_string_literal: true

require_relative "individual"

module Genalgo
  # The only boundary that invokes the objective and counts attempted evaluations.
  class Evaluator
    attr_reader :evaluations

    def initialize(bounds:, max_evaluations:, &objective)
      raise ArgumentError, "An objective block is required" unless objective

      @bounds = bounds
      @max_evaluations = max_evaluations
      @objective = objective
      @evaluations = 0
    end

    def remaining
      @max_evaluations - evaluations
    end

    def evaluate(chromosome)
      raise EvaluationError, "Evaluation budget exhausted" unless remaining.positive?

      chromosome = @bounds.clamp(chromosome).freeze
      @evaluations += 1
      evaluate_objective(chromosome)
    end

    private

    def evaluate_objective(chromosome)
      fitness = @objective.call(chromosome)
      Individual.new(bounds: @bounds, chromosome: chromosome, fitness: fitness)
    rescue StandardError => e
      raise EvaluationError.new("Evaluation failed: #{e.message}",
                                context: { evaluations: evaluations, chromosome: chromosome }), cause: e
    end
  end
end
