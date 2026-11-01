# frozen_string_literal: true

require_relative "individual"

module Genalgo
  # Internal mutable slots containing immutable evaluated individuals.
  class Population
    include Enumerable

    attr_reader :best_individual

    def initialize(individuals)
      unless individuals.is_a?(Array) && !individuals.empty? && individuals.first.is_a?(Individual)
        raise PopulationError, "Population requires a non-empty array of evaluated individuals"
      end

      @bounds = individuals.first.bounds
      validate_individuals!(individuals)
      @individuals = individuals.dup
      @indices = (0...size).to_a.freeze
      @best_individual = @individuals.min_by(&:fitness)
    end

    def each(&block)
      @individuals.each(&block)
    end

    def size
      @individuals.size
    end

    def [](index)
      @individuals.fetch(index)
    end

    def sample_indices(count, random:)
      unless count.is_a?(Integer) && count.between?(1, size)
        raise PopulationError, "Sample size must be an integer between 1 and #{size}"
      end

      @indices.sample(count, random: random)
    end

    def replace(indices, individuals)
      validate_replacement!(indices, individuals)
      removed_best = indices.any? { |index| self[index].equal?(best_individual) }
      indices.zip(individuals).each { |index, individual| @individuals[index] = individual }
      update_best(individuals, removed_best: removed_best)
      self
    end

    private

    def update_best(individuals, removed_best:)
      @best_individual = if removed_best && !individuals.include?(best_individual)
                           @individuals.min_by(&:fitness)
                         else
                           [best_individual, *individuals].min_by(&:fitness)
                         end
    end

    def validate_individuals!(individuals)
      return if individuals.all? do |individual|
        individual.is_a?(Individual) && individual.frozen? && individual.bounds.equal?(@bounds)
      end

      raise PopulationError, "Population requires evaluated individuals sharing one Bounds object"
    end

    def validate_replacement!(indices, individuals)
      valid = indices.size == individuals.size && indices.uniq.size == indices.size
      valid &&= indices.all? { |index| index.is_a?(Integer) && index.between?(0, size - 1) }
      raise PopulationError, "Replacement requires distinct valid slots and equally many individuals" unless valid

      validate_individuals!(individuals)
    end
  end
end
