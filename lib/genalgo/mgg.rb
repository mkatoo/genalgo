# frozen_string_literal: true

require_relative "individual"
require_relative "blx_alpha_crossover"
require_relative "simplex_crossover"
require_relative "elite_roulette_selection"
require_relative "generation_manager"

module Genalgo
  # Minimal Generation Gap (MGG)
  class MGG
    class << self
      attr_accessor :n_dim, :lower_limit, :upper_limit, :evaluation_function, :crossover

      def evaluations_per_generation
        generation_manager.evaluations_per_generation
      end

      def next_generation(population)
        generation_manager.next_generation(population)
      end

      private

      def generation_manager
        @generation_manager ||= create_generation_manager
      end

      def create_generation_manager
        crossover_strategy = create_crossover_strategy
        selection_strategy = EliteRouletteSelection.new
        bounds = { upper: @upper_limit, lower: @lower_limit }

        GenerationManager.new(
          crossover_strategy,
          selection_strategy,
          @evaluation_function,
          @n_dim,
          bounds
        )
      end

      def create_crossover_strategy
        case @crossover
        when :blx_alpha
          BlxAlphaCrossover.new
        when :simplex
          SimplexCrossover.new(@n_dim)
        else
          raise ArgumentError, "Unknown crossover type: #{@crossover}"
        end
      end
    end
  end
end
