# frozen_string_literal: true

RSpec.describe Genalgo::Optimizer do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1.0, 10.0, 3.0], upper: [1.0, 20.0, 3.0]) }
  let(:objective) { ->(chromosome) { chromosome.sum { |gene| gene * gene } } }
  let(:params) { { bounds: bounds, population_size: 6, max_evaluations: 20, seed: 14 } }

  [Genalgo::Crossovers::BlxAlpha.new, Genalgo::Crossovers::Simplex.new].each do |crossover|
    context "with #{crossover.class.name}" do
      let(:configuration) { Genalgo::Configuration.new(**params, crossover: crossover) }
      subject(:optimizer) { described_class.new(configuration) }

      it "returns evaluated individuals, bounds, monotonic best fitness, and accurate history" do
        calls = 0
        result = optimizer.run do |chromosome|
          calls += 1
          objective.call(chromosome)
        end

        expect(result).to be_a(Genalgo::Result)
        expect(result.configuration).to be(configuration)
        expect(result.seed).to eq(14)
        expect(result.evaluations).to eq(calls).and eq(20)
        expect(result.history.map(&:evaluations)).to eq((6..20).step(2).to_a)
        expect(result.population.size).to eq(6)
        expect(result.best_individual).to be(result.population.min_by(&:fitness))
        expect(result.history.last.best_individual.fitness).to eq(result.best_individual.fitness)
        fitness = result.history.map { |entry| entry.best_individual.fitness }
        expect(fitness.each_cons(2).all? { |previous, current| current <= previous }).to be(true)
        (result.population + result.history.map(&:best_individual)).each do |individual|
          expect(bounds.within_bounds?(individual.chromosome)).to be(true)
          expect(individual.chromosome.last).to eq(3.0)
          expect(individual.fitness).to eq(objective.call(individual.chromosome))
        end
      end

      [6, 7, 12, 13].each do |budget|
        it "uses only complete two-child steps within a budget of #{budget}" do
          calls = 0
          result = described_class.new(configuration.with(max_evaluations: budget)).run { calls += 1 }

          expect(calls).to eq(6 + (((budget - 6) / 2) * 2))
          expect(result.evaluations).to eq(calls)
          expect(result.history.last.evaluations).to eq(calls)
        end
      end

      it "repeats runs without sharing mutable results" do
        first = optimizer.run(&objective)
        second = optimizer.run(&objective)

        expect(snapshot(second)).to eq(snapshot(first))
        expect(first).not_to be(second)
        expect(first.population).not_to be(second.population)
        expect(first.history).not_to be(second.history)
        expect(first).to be_frozen
        expect { first.population.clear }.to raise_error(FrozenError)
        expect { first.history.clear }.to raise_error(FrozenError)
        expect { first.history.first.best_individual.chromosome.fill(99) }.to raise_error(FrozenError)
        expect(first.history).to all(be_frozen)
      end

      [1, 7].each do |failure_at|
        it "preserves completed results and can run again after failure on evaluation #{failure_at}" do
          previous = optimizer.run(&objective)
          expected = snapshot(previous)
          calls = 0

          expect do
            optimizer.run do |genes|
              calls += 1
              raise "objective failure" if calls == failure_at

              objective.call(genes)
            end
          end.to raise_error(Genalgo::EvaluationError) { |error| expect(error.context[:evaluations]).to eq(failure_at) }

          expect(snapshot(previous)).to eq(expected)
          expect(snapshot(optimizer.run(&objective))).to eq(expected)
        end
      end

      it "keeps random streams independent of global randomness and nested runs" do
        expected = snapshot(optimizer.run(&objective))
        nested = nil
        calls = 0
        result = optimizer.run do |genes|
          calls += 1
          Random.srand(calls)
          3.times { Random.rand }
          nested = optimizer.run(&objective) if [1, 7].include?(calls)
          objective.call(genes)
        end

        expect(snapshot(result)).to eq(expected)
        expect(snapshot(nested)).to eq(expected)
      ensure
        Random.srand(RSpec.configuration.seed)
      end

      it "leaves the global random stream unchanged" do
        expected = Random.new(812)
        Random.srand(812)
        optimizer.run(&objective)

        expect(Array.new(5) { Random.rand }).to eq(Array.new(5) { expected.rand })
      ensure
        Random.srand(RSpec.configuration.seed)
      end

      [1, 2, 5, 10].each do |dimension|
        it "supports #{dimension} dimensions at the minimum population size" do
          bounds = Genalgo::Bounds.new(lower: Array.new(dimension, -1), upper: Array.new(dimension, 1))
          count = crossover.parent_count(dimension)
          configuration = Genalgo::Configuration.new(bounds: bounds, population_size: count,
                                                     max_evaluations: count + 4, crossover: crossover, seed: 123)
          result = described_class.new(configuration).run(&objective)

          expect(result.population.size).to eq(count)
          expect(result.evaluations).to eq(count + 4)
          expect(result.population.map(&:chromosome)).to all(satisfy { |genes| bounds.within_bounds?(genes) })
        end
      end

      it "keeps all fixed coordinates exact" do
        bounds = Genalgo::Bounds.new(lower: [0.5, 3.0, 0.0], upper: [0.5, 3.0, 0.0])
        result = described_class.new(configuration.with(bounds: bounds)).run(&objective)

        expect(result.population.map(&:chromosome)).to all(eq([0.5, 3.0, 0.0]))
        expect(result.population.map(&:fitness)).to all(eq(9.25))
      end
    end
  end

  it "requires a validated configuration and an objective" do
    expect { described_class.new({}) }.to raise_error(ArgumentError, /Configuration/)
    configuration = Genalgo::Configuration.new(**params)
    expect { described_class.new(configuration).run }.to raise_error(ArgumentError, /objective/)
  end

  private

  def snapshot(result)
    {
      population: result.population.map { |individual| [individual.chromosome, individual.fitness] },
      history: result.history.map do |entry|
        [entry.evaluations, entry.best_individual.chromosome, entry.best_individual.fitness]
      end
    }
  end
end
