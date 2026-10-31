# frozen_string_literal: true

RSpec.describe Genalgo::MGG do
  let(:evaluation_function) { ->(chromosome) { chromosome.sum { |gene| gene * gene } } }
  let(:random) { Random.new(params[:seed]) }
  let(:params) do
    {
      n_pop: 6, n_dim: 3, n_eval: 20, lower_limit: -1.0, upper_limit: 1.0,
      evaluation_function: evaluation_function, seed: 123
    }
  end

  %i[blx_alpha simplex].each do |crossover|
    context "with #{crossover} crossover" do
      subject(:generation) { described_class.new(configuration, random: random) }

      let(:configuration) { Genalgo::Configuration.new(params.merge(crossover: crossover)) }
      let(:population) do
        population = Genalgo::Population.new(
          n_pop: configuration.n_pop, bounds: configuration.bounds_object, random: random
        )
        population.each { |individual| individual.fitness = evaluation_function.call(individual.chromosome) }
        population
      end

      it "evaluates two children, preserves the population size, and retains the best fitness" do
        initial_population = population
        best_fitness = initial_population.best_individual.fitness
        expect(evaluation_function).to receive(:call).twice.and_call_original

        result = generation.next_generation(initial_population)

        expect(generation.evaluations_per_generation).to eq(2)
        expect(result).to be_a(Genalgo::Population)
        expect(result.size).to eq(configuration.n_pop)
        expect(result.best_individual.fitness).to be <= best_fitness
        result.each do |individual|
          expect(individual).to be_within_bounds
          expect(individual.chromosome.size).to eq(configuration.n_dim)
          expect(individual.fitness).to eq(individual.chromosome.sum { |gene| gene * gene })
        end
      end

      it "evolves successive generations using the same instance" do
        current = population
        best_fitness = current.best_individual.fitness
        expect(evaluation_function).to receive(:call).exactly(6).times.and_call_original

        3.times { current = generation.next_generation(current) }

        expect(current.size).to eq(configuration.n_pop)
        expect(current).to all(be_within_bounds)
        expect(current.best_individual.fitness).to be <= best_fitness
      end

      it "preserves the input individuals, chromosomes, and fitness values" do
        original_individuals = population.to_a
        original_values = population.map { |individual| [individual.chromosome.dup, individual.fitness] }

        result = generation.next_generation(population)

        expect(population.to_a).to eq(original_individuals)
        expect(population.map { |individual| [individual.chromosome, individual.fitness] }).to eq(original_values)

        result.each do |individual|
          individual.chromosome.fill(configuration.lower_limit)
          individual.fitness = -100.0
        end

        expect(population.map { |individual| [individual.chromosome, individual.fitness] }).to eq(original_values)
      end

      it "supports the minimum population required by the crossover" do
        minimum = crossover == :simplex ? configuration.n_dim + 1 : 2
        minimum_configuration = Genalgo::Configuration.new(configuration.to_h.merge(n_pop: minimum))
        generation = described_class.new(minimum_configuration, random: random)
        population = Genalgo::Population.new(
          n_pop: minimum, bounds: minimum_configuration.bounds_object, random: random
        )
        population.each { |individual| individual.fitness = evaluation_function.call(individual.chromosome) }

        result = generation.next_generation(population)

        expect(result.size).to eq(minimum)
        expect(result).to all(be_within_bounds)
      end

      it "keeps its settings when another instance uses different dimensions, bounds, and evaluation" do
        first_generation = generation
        first_population = population
        other_evaluation = ->(_chromosome) { -100.0 }
        other_params = params.merge(
          n_pop: 2, n_dim: 1, lower_limit: 10.0, upper_limit: 11.0,
          crossover: crossover == :simplex ? :blx_alpha : :simplex, evaluation_function: other_evaluation
        )
        other_configuration = Genalgo::Configuration.new(other_params)
        other_random = Random.new(other_configuration.seed)
        other_generation = described_class.new(other_configuration, random: other_random)
        other_population = Genalgo::Population.new(
          n_pop: 2, bounds: other_configuration.bounds_object, random: other_random
        )
        other_population.each { |individual| individual.fitness = 0.0 }
        expect(evaluation_function).to receive(:call).twice.and_call_original
        expect(other_evaluation).to receive(:call).twice.and_call_original

        first_result = first_generation.next_generation(first_population)
        other_result = other_generation.next_generation(other_population)

        expect(first_result.size).to eq(configuration.n_pop)
        first_result.each do |individual|
          expect(individual.bounds).to be(configuration.bounds_object)
          expect(individual.fitness).to eq(individual.chromosome.sum { |gene| gene * gene })
        end
        expect(other_result.size).to eq(2)
        expect(other_result).to all(be_within_bounds)
        expect(other_result.map(&:n_dim)).to all(eq(1))
        expect(other_result.best_individual.fitness).to eq(-100.0)
      end
    end
  end
end
