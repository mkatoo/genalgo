# frozen_string_literal: true

RSpec.describe Genalgo::Individual do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1.0, 10.0, 3.0], upper: [1.0, 20.0, 3.0]) }
  subject(:individual) { described_class.new(bounds: bounds, chromosome: [0.0, 15.0, 3.0]) }

  it "owns a chromosome within shared bounds and has no fitness before evaluation" do
    expect(individual.bounds).to be(bounds)
    expect(individual.n_dim).to eq(3)
    expect(individual).to be_within_bounds
    expect(individual.fitness).to be_nil
  end

  it "copies the supplied chromosome so callers cannot mutate it indirectly" do
    chromosome = [0.0, 15.0, 3.0]
    individual = described_class.new(bounds: bounds, chromosome: chromosome)
    chromosome[0] = 99.0

    expect(individual.chromosome).to eq([0.0, 15.0, 3.0])
  end

  it "clamps each coordinate at initialization and assignment" do
    individual = described_class.new(bounds: bounds, chromosome: [-2.0, 30.0, 99.0])
    expect(individual.chromosome).to eq([-1.0, 20.0, 3.0])

    individual.chromosome = [2.0, 0.0, -99.0]
    expect(individual.chromosome).to eq([1.0, 10.0, 3.0])
  end

  it "rejects inconsistent chromosome dimensions without changing the existing chromosome" do
    expect { individual.chromosome = [0.0] }.to raise_error(ArgumentError)
    expect(individual.chromosome).to eq([0.0, 15.0, 3.0])
    expect { described_class.new(bounds: bounds, chromosome: [0.0, 15.0]) }.to raise_error(ArgumentError)
  end

  it "allows positive, zero, and negative fitness values" do
    [42.0, 0.0, -1.0].each do |fitness|
      individual.fitness = fitness
      expect(individual.fitness).to eq(fitness)
    end
  end

  it "copies chromosome and fitness independently without creating a random generator" do
    original = individual
    original.fitness = 42.0
    expect(Random).not_to receive(:new)

    copy = original.dup

    expect(copy.bounds).to be(bounds)
    expect(copy.chromosome).to eq(original.chromosome)
    expect(copy.chromosome).not_to be(original.chromosome)
    expect(copy.fitness).to eq(42.0)
    copy.chromosome[0] = 999.0
    copy.fitness = -1.0
    expect(original.chromosome[0]).to eq(0.0)
    expect(original.fitness).to eq(42.0)
  end
end
