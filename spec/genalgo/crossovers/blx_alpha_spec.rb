# frozen_string_literal: true

require_relative "../../support/crossover_examples"

RSpec.describe Genalgo::Crossovers::BlxAlpha do
  let(:bounds) { Genalgo::Bounds.new(lower: [-10, 100, 3], upper: [10, 200, 3]) }
  let(:parents) { [[-2, 120, 3], [2, 160, 3]] }
  let(:random) { Random.new(123) }
  subject(:crossover) { described_class.new(alpha: 0.5) }

  it_behaves_like "an immutable crossover"

  it "samples offspring within bounds" do
    sampler = crossover.prepare(parents, bounds: bounds)
    children = Array.new(20) { sampler.call(random: random) }

    expect(children).to all(satisfy { |genes| bounds.within_bounds?(genes) })
  end

  it "expands each parental interval independently" do
    allow(random).to receive(:rand).and_return(0.0)

    expect(crossover.prepare(parents, bounds: bounds).call(random: random)).to eq([-4.0, 100.0, 3.0])
    expect(crossover.parent_count(bounds.dimension)).to eq(2)
  end

  it "clips intervals before sampling instead of clamping the resulting sample" do
    allow(random).to receive(:rand).and_return(0.25)

    sampler = crossover.prepare([[-9, 105, 3], [9, 195, 3]], bounds: bounds)

    expect(sampler.call(random: random)).to eq([-5.0, 125.0, 3.0])
  end

  it "is symmetric with respect to parent order" do
    allow(random).to receive(:rand).and_return(0.25)
    first = crossover.prepare(parents, bounds: bounds).call(random: random)
    second = crossover.prepare(parents.reverse, bounds: bounds).call(random: random)

    expect(first).to eq(second)
    expect(second).to eq([-2.0, 120.0, 3.0])
  end

  it "supports no expansion" do
    allow(random).to receive(:rand).and_return(0.0)

    sampler = described_class.new(alpha: 0).prepare(parents, bounds: bounds)

    expect(sampler.call(random: random)).to eq(parents.first)
  end

  [0.0, 0.5, Float::MAX].each do |alpha|
    it "samples finite coordinates when the parental width overflows with alpha #{alpha}" do
      bounds = Genalgo::Bounds.new(lower: [-Float::MAX], upper: [Float::MAX])
      allow(random).to receive(:rand).and_return(0.5)

      sampler = described_class.new(alpha: alpha).prepare([bounds.lower, bounds.upper], bounds: bounds)
      child = sampler.call(random: random)

      expect(child).to eq([0.0])
    end
  end

  it "clips an overflowing expansion to finite bounds before sampling" do
    bounds = Genalgo::Bounds.new(lower: [-10], upper: [10])
    allow(random).to receive(:rand).and_return(0.25)

    child = described_class.new(alpha: Float::MAX).prepare([[-2], [2]], bounds: bounds).call(random: random)

    expect(child).to eq([-5.0])
  end

  [[], [[0]], [[0, 150, 3], [20, 150, 3]]].each do |parents|
    it "rejects inconsistent parents #{parents.inspect}" do
      expect { crossover.prepare(parents, bounds: bounds) }.to raise_error(Genalgo::StrategyError)
    end
  end

  [-1, Float::NAN, Float::INFINITY, Complex(1, 1), nil, 10**400].each do |alpha|
    it "rejects invalid alpha #{alpha.inspect}" do
      expect { described_class.new(alpha: alpha) }.to raise_error(Genalgo::ConfigurationError)
    end
  end
end
