# frozen_string_literal: true

RSpec.describe Genalgo::SimplexCrossover do
  let(:random) { Random.new(123) }
  let(:bounds) { Genalgo::Bounds.new(lower: [-1.0, 10.0, 3.0], upper: [1.0, 20.0, 3.0]) }
  let(:parents) do
    [[-1.0, 10.0, 3.0], [1.0, 10.0, 3.0], [-1.0, 20.0, 3.0], [1.0, 20.0, 3.0]].map do |chromosome|
      Genalgo::Individual.new(bounds: bounds, chromosome: chromosome)
    end
  end
  subject(:crossover) { described_class.new(random: random) }

  it "clamps expanded offspring separately for each coordinate, including fixed coordinates" do
    allow(random).to receive(:rand).and_return(0.0)

    child = crossover.crossover(parents)

    expect(child.chromosome).to eq([1.0, 20.0, 3.0])
    expect(child.bounds).to be(bounds)
  end

  it "preserves all parents and creates independent offspring" do
    original = parents.map { |parent| parent.chromosome.dup }
    child = crossover.crossover(parents)
    child.chromosome.fill(999.0)

    expect(parents.map(&:chromosome)).to eq(original)
    parents.each { |parent| expect(child).not_to be(parent) }
  end

  it "preserves identical parents" do
    identical = Array.new(4) { Genalgo::Individual.new(bounds: bounds, chromosome: [0.0, 15.0, 3.0]) }

    expect(crossover.crossover(identical).chromosome).to eq([0.0, 15.0, 3.0])
  end

  [0, 1, 3, 5].each do |count|
    it "rejects #{count} parents when the bounds require four" do
      candidates = Array.new(count) { |index| parents[index % parents.size] }

      expect { crossover.crossover(candidates) }.to raise_error(Genalgo::StrategyError)
    end
  end

  [1, 2, 4, 5].each do |dimension|
    it "derives #{dimension} dimensions from the parent bounds" do
      bounds = Genalgo::Bounds.new(lower: Array.new(dimension, -100.0), upper: Array.new(dimension, 100.0))
      parents = Array.new(dimension + 1) do |index|
        Genalgo::Individual.new(bounds: bounds, chromosome: Array.new(dimension, index.to_f))
      end

      child = crossover.crossover(parents)

      expect(child.n_dim).to eq(dimension)
      expect(child).to be_within_bounds
      expect(child.chromosome).to all(be_finite)
    end
  end

  it "reproduces offspring with an independent random generator using the same seed" do
    other = described_class.new(random: Random.new(123))

    first = Array.new(5) { crossover.crossover(parents).chromosome }
    second = Array.new(5) { other.crossover(parents).chromosome }

    expect(first).to eq(second)
    expect(first.uniq.size).to be > 1
  end
end
