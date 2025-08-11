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

      def evaluations_per_generation(configuration = nil)
        manager = configuration ? generation_manager_for_configuration(configuration) : generation_manager
        manager.evaluations_per_generation
      end

      def next_generation(population, configuration = nil)
        manager = configuration ? generation_manager_for_configuration(configuration) : generation_manager
        manager.next_generation(population)
      end

      private

      def generation_manager
        @generation_manager ||= create_generation_manager
      end

      def generation_manager_for_configuration(configuration)
        # Don't cache configuration-based managers to allow for different configurations
        create_generation_manager_for_configuration(configuration)
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

      def create_generation_manager_for_configuration(configuration)
        crossover_strategy = create_crossover_strategy_for_configuration(configuration)
        selection_strategy = EliteRouletteSelection.new

        GenerationManager.new(
          crossover_strategy,
          selection_strategy,
          configuration.evaluation_function,
          configuration.n_dim,
          configuration.bounds
        )
      end

      def create_crossover_strategy
        case @crossover
        when :blx_alpha
          BlxAlphaCrossover.new
        when :simplex
          SimplexCrossover.new(@n_dim)
        else
          raise Genalgo::StrategyError.new("Unknown crossover type: #{@crossover}",
                                           context: { crossover: @crossover, available_types: %i[blx_alpha simplex] })
        end
      end

      def create_crossover_strategy_for_configuration(configuration)
        case configuration.crossover
        when :blx_alpha
          BlxAlphaCrossover.new
        when :simplex
          SimplexCrossover.new(configuration.n_dim)
        else
          raise Genalgo::StrategyError.new("Unknown crossover type: #{configuration.crossover}",
                                           context: { crossover: configuration.crossover,
                                                      available_types: %i[blx_alpha simplex] })
        end
      end
    end
  end
end
