# frozen_string_literal: true

RSpec.describe Genalgo::EliteRouletteSelection do
  let(:random) { Random.new(123) }
  let(:bounds) { Genalgo::Bounds.new(lower: Array.new(3, -10.0), upper: Array.new(3, 10.0)) }
  let(:individuals) { [10.0, 5.0, 8.0, 2.0].map { |fitness| create_individual(fitness: fitness) } }
  subject(:selector) { described_class.new(random: random) }

  it "uses the default scaling factor when omitted" do
    explicit = described_class.new(random: Random.new(123), scaling_factor: described_class::DEFAULT_SCALING_FACTOR)

    expect(selector.select(individuals)).to eq(explicit.select(individuals))
  end

  describe "#select" do
    it "selects two distinct input individuals including the elite" do
      selected = selector.select(individuals)

      expect(selected.uniq.size).to eq(2)
      expect(selected - individuals).to be_empty
      expect(selected.last).to be(individuals.min_by(&:fitness))
    end

    it "leaves the input array and its order unchanged" do
      original = individuals.dup
      selector.select(individuals.freeze)

      expect(individuals).to eq(original)
    end

    it "selects the first non-elite interval when the random value is zero" do
      allow(random).to receive(:rand).and_return(0.0)

      expect(selector.select(individuals).map(&:fitness)).to eq([5.0, 2.0])
    end

    it "rejects inputs containing unevaluated individuals" do
      expect { selector.select([*individuals.first(3), nil]) }.to raise_error(Genalgo::StrategyError)
    end

    [0, 3, 5].each do |size|
      it "rejects a family of #{size} individuals" do
        family = Array.new(size, individuals.first)

        expect { selector.select(family) }.to raise_error(Genalgo::StrategyError)
      end
    end
  end

  describe "fitness scaling" do
    [0.0, 5.0, -5.0].each do |fitness|
      it "handles identical fitness values of #{fitness} without selecting an individual twice" do
        identical = Array.new(4) { create_individual(fitness: fitness) }

        expect(selector.select(identical).uniq.size).to eq(2)
      end
    end

    { 0.0 => 0.0, 0.5.prev_float => 0.0, 0.5 => 1.0, 1.0.prev_float => 1.0 }.each do |value, fitness|
      it "selects the expected weight interval for random value #{value}" do
        candidates = [-1.0, 0.0, 1.0, 1.0].map { |score| create_individual(fitness: score) }
        allow(random).to receive(:rand).and_return(value)
        selector = described_class.new(random: random, scaling_factor: 1.0)

        expect(selector.select(candidates).map(&:fitness)).to eq([fitness, -1.0])
      end
    end

    it "handles fitness ranges whose unscaled difference would overflow" do
      wide = [-1e308, -1e308, 1e307, 1e308].map { |fitness| create_individual(fitness: fitness) }
      allow(random).to receive(:rand).and_return(0.0)

      expect(selector.select(wide).map(&:fitness)).to eq([-1e308, -1e308])
    end

    it "handles a very small positive scaling factor" do
      tiny = described_class.new(random: random, scaling_factor: 1e-320)

      expect(tiny.select(individuals).uniq.size).to eq(2)
    end

    it "prefers individuals with better fitness" do
      diverse = [1.0, 100.0, 50.0, 10.0].map { |fitness| create_individual(fitness: fitness) }
      selections = Array.new(100) { selector.select(diverse).map(&:fitness) }

      expect(selections.count { |fitness| fitness.include?(10.0) })
        .to be > selections.count { |fitness| fitness.include?(100.0) }
    end

    it "produces different selection patterns with different scaling factors" do
      low = described_class.new(random: Random.new(123), scaling_factor: 0.1)
      high = described_class.new(random: Random.new(123), scaling_factor: 2.0)
      low_selections = Array.new(50) { low.select(individuals) }
      high_selections = Array.new(50) { high.select(individuals) }

      expect(low_selections).not_to eq(high_selections)
    end

    it "changes selection pressure with the scaling factor" do
      candidates = [0, 1, 2, 2].map { |fitness| create_individual(fitness: fitness) }
      allow(random).to receive(:rand).and_return(0.7)
      low = described_class.new(random: random, scaling_factor: 0.1)
      high = described_class.new(random: random, scaling_factor: 2.0)

      expect(low.select(candidates).map(&:fitness)).to eq([1.0, 0.0])
      expect(high.select(candidates).map(&:fitness)).to eq([2.0, 0.0])
    end

    [0, -0.1, Float::NAN, Float::INFINITY, Complex(1, 1), nil, Rational(1, 10**400)].each do |factor|
      it "rejects an invalid scaling factor #{factor.inspect}" do
        expect { described_class.new(random: random, scaling_factor: factor) }
          .to raise_error(Genalgo::ConfigurationError)
      end
    end
  end

  describe "randomness and reproducibility" do
    it "reproduces selections with independent random generators using the same seed" do
      first = described_class.new(random: Random.new(123))
      second = described_class.new(random: Random.new(123))

      expect(Array.new(5) { first.select(individuals) }).to eq(Array.new(5) { second.select(individuals) })
    end

    it "produces varied selections on successive calls" do
      selections = Array.new(20) { selector.select(individuals).map(&:fitness).sort }

      expect(selections.uniq.size).to be > 1
    end
  end

  private

  def create_individual(fitness:)
    Genalgo::Evaluator.new(bounds: bounds, max_evaluations: 1) { fitness }.evaluate([1.0, 2.0, 3.0])
  end
end
