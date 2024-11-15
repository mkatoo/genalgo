# frozen_string_literal: true

require "forwardable"

module Genalgo
  # History
  class History
    include Enumerable
    extend Forwardable
    def_delegators :@history, :each, :first, :last

    def initialize
      @history = []
    end

    def add(best_individual, evaluations)
      @history << Data.new(best_individual, evaluations)
    end

    # Data
    class Data
      attr_reader :best_individual, :evaluations

      def initialize(best_individual, evaluations)
        @best_individual = best_individual.dup
        @evaluations = evaluations
      end
    end
  end
end
