# frozen_string_literal: true

RSpec.describe Genalgo::MGG do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1, -1, -1], upper: [1, 1, 1]) }
  let(:individuals) do
    Array.new(6) do |index|
      genes = Array.new(3, index / 10.0)
      Genalgo::Individual.new(bounds: bounds, chromosome: genes, fitness: genes.sum { |gene| gene * gene })
    end
  end
  let(:population) { Genalgo::Population.new(individuals) }
  let(:random) { Random.new(123) }

  [Genalgo::Crossovers::BlxAlpha.new, Genalgo::Crossovers::Simplex.new].each do |crossover|
    context "with #{crossover.class.name}" do
      let(:configuration) do
        Genalgo::Configuration.new(bounds: bounds, population_size: 6, max_evaluations: 20,
                                   crossover: crossover, seed: 123)
      end
      let(:evaluator) do
        Genalgo::Evaluator.new(bounds: bounds, max_evaluations: 4) { |genes| genes.sum { |gene| gene * gene } }
      end
      subject(:generation) { described_class.new(configuration, evaluator: evaluator, random: random) }

      it "evaluates two children and retains the best across successive updates" do
        original_best = population.best_individual
        2.times { generation.step(population) }

        expect(evaluator.evaluations).to eq(4)
        expect(population.size).to eq(6)
        expect(population.best_individual.fitness).to be <= original_best.fitness
        expect(population.map(&:chromosome)).to all(satisfy { |genes| bounds.within_bounds?(genes) })
      end

      it "keeps slots unchanged if the second child evaluation fails" do
        calls = 0
        evaluator = Genalgo::Evaluator.new(bounds: bounds, max_evaluations: 2) do
          calls += 1
          raise "failed child" if calls == 2

          0
        end
        generation = described_class.new(configuration, evaluator: evaluator, random: random)
        original = population.to_a

        expect { generation.step(population) }.to raise_error(Genalgo::EvaluationError)
        expect(evaluator.evaluations).to eq(2)
        expect(population.to_a).to eq(original)
      end

      it "refuses an incomplete step before evaluating either child" do
        evaluator = Genalgo::Evaluator.new(bounds: bounds, max_evaluations: 1) { raise "must not be called" }
        generation = described_class.new(configuration, evaluator: evaluator, random: random)

        expect { generation.step(population) }.to raise_error(Genalgo::EvaluationError, /two children/)
        expect(evaluator.evaluations).to eq(0)
      end
    end
  end

  it "uses all Simplex parents for crossover but replaces only the chosen two" do
    indices = [0, 1, 2, 3]
    original = population.to_a
    configuration = Genalgo::Configuration.new(bounds: bounds, population_size: 6, max_evaluations: 20,
                                               crossover: Genalgo::Crossovers::Simplex.new)
    evaluator = Genalgo::Evaluator.new(bounds: bounds, max_evaluations: 2) { |genes| genes.sum { |gene| gene * gene } }
    expect(population).to receive(:sample_indices).with(4, random: random).and_return(indices)
    allow(indices).to receive(:sample).with(2, random: random).and_return([1, 3])

    described_class.new(configuration, evaluator: evaluator, random: random).step(population)

    [0, 2, 4, 5].each { |index| expect(population[index]).to be(original[index]) }
    expect(population.size).to eq(6)
    expect(evaluator.evaluations).to eq(2)
  end
end
