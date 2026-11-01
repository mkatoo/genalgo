# frozen_string_literal: true

RSpec.describe Genalgo::Crossovers::BlxAlpha do
  let(:bounds) { Genalgo::Bounds.new(lower: [-10, 100, 3], upper: [10, 200, 3]) }
  let(:parents) { [[-2, 120, 3], [2, 160, 3]] }
  let(:random) { Random.new(123) }
  subject(:crossover) { described_class.new(alpha: 0.5) }

  it "expands each parental interval independently" do
    allow(random).to receive(:rand).and_return(0.0)

    expect(crossover.call(parents, bounds: bounds, random: random)).to eq([-4.0, 100.0, 3.0])
    expect(crossover.parent_count(bounds.dimension)).to eq(2)
  end

  it "clips intervals before sampling instead of clamping the resulting sample" do
    allow(random).to receive(:rand).and_return(0.25)

    expect(crossover.call([[-9, 105, 3], [9, 195, 3]], bounds: bounds, random: random)).to eq([-5.0, 125.0, 3.0])
  end

  it "is symmetric and leaves both parents untouched" do
    allow(random).to receive(:rand).and_return(0.25)
    first = crossover.call(parents, bounds: bounds, random: random)
    second = crossover.call(parents.reverse, bounds: bounds, random: random)
    first.fill(999)

    expect(second).to eq([-2.0, 120.0, 3.0])
    expect(parents).to eq([[-2, 120, 3], [2, 160, 3]])
    expect(crossover).to be_frozen
  end

  it "supports no expansion and identical parents" do
    allow(random).to receive(:rand).and_return(0.0)

    expect(described_class.new(alpha: 0).call(parents, bounds: bounds, random: random)).to eq(parents.first)
    expect(crossover.call([parents.first, parents.first], bounds: bounds, random: random)).to eq(parents.first)
  end

  it "reproduces offspring using only the supplied random stream" do
    first = Array.new(5) { crossover.call(parents, bounds: bounds, random: random) }
    other_random = Random.new(123)
    second = Array.new(5) { crossover.call(parents, bounds: bounds, random: other_random) }

    expect(first).to eq(second)
    expect(first.uniq.size).to be > 1
    expect(first).to all(satisfy { |genes| bounds.within_bounds?(genes) })
  end

  [[], [[0]], [[0, 150, 3], [20, 150, 3]]].each do |parents|
    it "rejects inconsistent parents #{parents.inspect}" do
      expect { crossover.call(parents, bounds: bounds, random: random) }.to raise_error(Genalgo::StrategyError)
    end
  end

  [-1, Float::NAN, Float::INFINITY, Complex(1, 1), nil, 10**400].each do |alpha|
    it "rejects invalid alpha #{alpha.inspect}" do
      expect { described_class.new(alpha: alpha) }.to raise_error(Genalgo::ConfigurationError)
    end
  end
end
