# frozen_string_literal: true

RSpec.describe Genalgo::Crossovers::Simplex do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1, 10, 3], upper: [1, 20, 3]) }
  let(:parents) { [[-1, 10, 3], [1, 10, 3], [-1, 20, 3], [1, 20, 3]] }
  let(:random) { Random.new(123) }
  subject(:crossover) { described_class.new }

  it "clamps expanded offspring separately for each coordinate" do
    allow(random).to receive(:rand).and_return(0.0)

    expect(crossover.call(parents, bounds: bounds, random: random)).to eq([1.0, 20.0, 3.0])
    expect(crossover.parent_count(3)).to eq(4)
  end

  it "uses a fractional centroid for integer coordinates" do
    bounds = Genalgo::Bounds.new(lower: [-10], upper: [10])
    allow(random).to receive(:rand).and_return(0.0)

    child = crossover.call([[0], [1]], bounds: bounds, random: random)

    expect(child.first).to be_within(1e-12).of(0.5 + (Math.sqrt(3) / 2))
  end

  it "applies the recursive simplex coefficients in two dimensions" do
    bounds = Genalgo::Bounds.new(lower: [-100, -100], upper: [100, 100])
    allow(random).to receive(:rand).and_return(0.25, 0.25)

    child = crossover.call([[0, 0], [2, 0], [0, 2]], bounds: bounds, random: random)

    expect(child).to match([be_within(1e-12).of(5.0 / 6), be_within(1e-12).of(4.0 / 3)])
  end

  it "preserves parents and identical chromosomes" do
    original = parents.map(&:dup)
    crossover.call(parents, bounds: bounds, random: random).fill(999)

    expect(parents).to eq(original)
    expect(crossover.call(Array.new(4) { [0, 15, 3] }, bounds: bounds, random: random)).to eq([0.0, 15.0, 3.0])
    expect(crossover).to be_frozen
  end

  [0, 1, 3, 5].each do |count|
    it "rejects #{count} parents when the dimension requires four" do
      candidates = Array.new(count) { parents.first }

      expect { crossover.call(candidates, bounds: bounds, random: random) }.to raise_error(Genalgo::StrategyError)
    end
  end

  it "rejects mismatched dimensions and out-of-bounds parents" do
    [[0], [99, 15, 3]].each do |invalid|
      expect { crossover.call([invalid, *parents.drop(1)], bounds: bounds, random: random) }
        .to raise_error(Genalgo::StrategyError)
    end
  end

  it "reproduces offspring using independent generators with the same seed" do
    first = Array.new(5) { crossover.call(parents, bounds: bounds, random: random) }
    other_random = Random.new(123)
    second = Array.new(5) { crossover.call(parents, bounds: bounds, random: other_random) }

    expect(first).to eq(second)
    expect(first.uniq.size).to be > 1
  end
end
