# frozen_string_literal: true

require_relative "../../support/crossover_examples"

RSpec.describe Genalgo::Crossovers::BlxAlpha do
  let(:bounds) { Genalgo::Bounds.new(lower: [-10, 100, 3], upper: [10, 200, 3]) }
  let(:parents) { [[-2, 120, 3], [2, 160, 3]] }
  let(:random) { Random.new(123) }
  subject(:crossover) { described_class.new(alpha: 0.5) }

  it_behaves_like "a bounded immutable crossover"

  it "expands each parental interval independently" do
    allow(random).to receive(:rand).and_return(0.0)

    expect(crossover.call(parents, bounds: bounds, random: random)).to eq([-4.0, 100.0, 3.0])
    expect(crossover.parent_count(bounds.dimension)).to eq(2)
  end

  it "clips intervals before sampling instead of clamping the resulting sample" do
    allow(random).to receive(:rand).and_return(0.25)

    expect(crossover.call([[-9, 105, 3], [9, 195, 3]], bounds: bounds, random: random)).to eq([-5.0, 125.0, 3.0])
  end

  it "is symmetric with respect to parent order" do
    allow(random).to receive(:rand).and_return(0.25)
    first = crossover.call(parents, bounds: bounds, random: random)
    second = crossover.call(parents.reverse, bounds: bounds, random: random)

    expect(first).to eq(second)
    expect(second).to eq([-2.0, 120.0, 3.0])
  end

  it "supports no expansion" do
    allow(random).to receive(:rand).and_return(0.0)

    expect(described_class.new(alpha: 0).call(parents, bounds: bounds, random: random)).to eq(parents.first)
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
