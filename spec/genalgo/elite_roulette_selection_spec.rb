# frozen_string_literal: true

RSpec.describe Genalgo::EliteRouletteSelection do
  let(:random) { Random.new(123) }
  let(:bounds) { Genalgo::Bounds.new(lower: Array.new(3, -10.0), upper: Array.new(3, 10.0)) }
  let(:individuals) { [10.0, 5.0, 8.0, 2.0, 6.0].map { |fitness| create_individual(fitness: fitness) } }
  subject(:selector) { described_class.new(random: random) }

  describe "#select" do
    [1, 3, 5].each do |size|
      it "selects #{size} distinct input individuals including the elite" do
        selected = selector.select(individuals, size)

        expect(selected.size).to eq(size)
        expect(selected.uniq.size).to eq(size)
        expect(selected - individuals).to be_empty
        expect(selected).to include(individuals.min_by(&:fitness))
      end
    end

    it "leaves the input array and its order unchanged" do
      original = individuals.dup
      selector.select(individuals, 3)

      expect(individuals).to eq(original)
    end

    it "returns an empty array when selecting zero individuals" do
      expect(selector.select(individuals, 0)).to be_empty
    end

    it "selects from a single-individual population" do
      single = [individuals.first]

      expect(selector.select(single, 1)).to eq(single)
    end

    it "selects without replacement even when the random value is always zero" do
      allow(random).to receive(:rand).and_return(0.0)

      expect(selector.select(individuals, individuals.size)).to match_array(individuals)
    end

    it "selects the first non-elite interval when the random value is zero" do
      allow(random).to receive(:rand).and_return(0.0)

      expect(selector.select(individuals, 2).map(&:fitness)).to eq([5.0, 2.0])
    end

    it "rejects selecting from an empty array" do
      expect { selector.select([], 1) }.to raise_error(Genalgo::StrategyError)
    end

    [-1, 1.5, nil, 6].each do |size|
      it "rejects an invalid selection size #{size.inspect}" do
        expect { selector.select(individuals, size) }.to raise_error(Genalgo::StrategyError)
      end
    end
  end

  describe "fitness scaling" do
    it "handles identical fitness values without selecting an individual twice" do
      identical = Array.new(4) { create_individual(fitness: 5.0) }
      selected = selector.select(identical, 2)

      expect(selected.size).to eq(2)
      expect(selected.uniq.size).to eq(2)
      expect(selected - identical).to be_empty
    end

    it "handles a linear fitness progression" do
      linear = (1..5).map { |index| create_individual(fitness: index * 2.0) }
      selected = selector.select(linear, 3)

      expect(selected.size).to eq(3)
      expect(selected).to include(linear.first)
    end

    { 0.0 => 0.0, 0.75.prev_float => 0.0, 0.75 => 1.0, 1.0.prev_float => 1.0 }.each do |value, fitness|
      it "selects the expected weight interval for random value #{value}" do
        candidates = [-1.0, 0.0, 1.0].map { |score| create_individual(fitness: score) }
        allow(random).to receive(:rand).and_return(value)

        expect(selector.select(candidates, 2).map(&:fitness)).to eq([fitness, -1.0])
      end
    end

    it "rescales the remaining fitness range after selecting each individual" do
      candidates = [0, 1, 2, 3].map { |fitness| create_individual(fitness: fitness) }
      allow(random).to receive(:rand).and_return(0.0, 0.7)

      expect(selector.select(candidates, 3).map(&:fitness)).to eq([1.0, 2.0, 0.0])
    end

    it "handles fitness ranges whose unscaled difference would overflow" do
      wide = [-1e308, -1e307, 1e307, 1e308].map { |fitness| create_individual(fitness: fitness) }

      expect(selector.select(wide, 4)).to match_array(wide)
    end

    it "handles a very small positive scaling factor" do
      tiny = described_class.new(random: random, scaling_factor: 1e-320)

      expect(tiny.select(individuals, 3).uniq.size).to eq(3)
    end

    it "prefers individuals with better fitness" do
      diverse = [1.0, 100.0, 50.0, 10.0, 75.0].map { |fitness| create_individual(fitness: fitness) }
      selections = Array.new(100) { selector.select(diverse, 3).map(&:fitness) }

      expect(selections.count { |fitness| fitness.include?(10.0) })
        .to be > selections.count { |fitness| fitness.include?(100.0) }
    end

    it "produces different selection patterns with different scaling factors" do
      low = described_class.new(random: Random.new(123), scaling_factor: 0.1)
      high = described_class.new(random: Random.new(123), scaling_factor: 2.0)
      low_selections = Array.new(50) { low.select(individuals, 3) }
      high_selections = Array.new(50) { high.select(individuals, 3) }

      expect(low_selections).not_to eq(high_selections)
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

      expect(Array.new(5) { first.select(individuals, 4) }).to eq(Array.new(5) { second.select(individuals, 4) })
    end

    it "produces varied selections on successive calls" do
      selections = Array.new(20) { selector.select(individuals, 3).map(&:fitness).sort }

      expect(selections.uniq.size).to be > 1
    end
  end

  private

  def create_individual(fitness:)
    Genalgo::Individual.new(bounds: bounds, chromosome: [1.0, 2.0, 3.0], fitness: fitness)
  end
end
