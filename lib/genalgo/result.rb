# frozen_string_literal: true

module Genalgo
  # A completed run with immutable collections and shared immutable individuals.
  class Result
    attr_reader :configuration, :population, :history, :evaluations, :best_individual

    def initialize(configuration:, population:, history:, evaluations:)
      @configuration = configuration
      @population = population.to_a.dup.freeze
      @history = history.dup.freeze
      @evaluations = evaluations
      @best_individual = @population.min_by(&:fitness)
      freeze
    end

    def seed
      configuration.seed
    end

    # The best individual and actual evaluation count after a completed update.
    class Snapshot
      attr_reader :best_individual, :evaluations

      def initialize(best_individual:, evaluations:)
        @best_individual = best_individual
        @evaluations = evaluations
        freeze
      end
    end
  end
end
