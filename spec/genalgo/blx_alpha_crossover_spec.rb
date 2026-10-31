# frozen_string_literal: true

RSpec.describe Genalgo::BlxAlphaCrossover do
  let(:random) { Random.new(123) }
  let(:bounds) { Genalgo::Bounds.new(lower: [-10.0, 100.0, 3.0], upper: [10.0, 200.0, 3.0]) }
  let(:parent1) { Genalgo::Individual.new(bounds: bounds, chromosome: [-2.0, 120.0, 3.0]) }
  let(:parent2) { Genalgo::Individual.new(bounds: bounds, chromosome: [2.0, 160.0, 3.0]) }
  subject(:crossover) { described_class.new(random: random, alpha: 0.5) }

  it "expands the parent interval separately for each coordinate" do
    allow(random).to receive(:rand).and_return(0.0)

    child = crossover.crossover(parent1, parent2)

    expect(child.chromosome).to eq([-4.0, 100.0, 3.0])
    expect(child.bounds).to be(bounds)
  end

  it "clips expanded intervals to each coordinate's bounds before sampling" do
    parent1.chromosome = [-9.0, 105.0, 3.0]
    parent2.chromosome = [9.0, 195.0, 3.0]
    allow(random).to receive(:rand).and_return(0.25)

    expect(crossover.crossover(parent1, parent2).chromosome).to eq([-5.0, 125.0, 3.0])
  end

  it "uses the same interval when parent order is reversed" do
    allow(random).to receive(:rand).and_return(0.25)

    first = crossover.crossover(parent1, parent2)
    second = crossover.crossover(parent2, parent1)

    expect(first.chromosome).to eq(second.chromosome)
  end

  it "honors a custom alpha without expansion when alpha is zero" do
    crossover = described_class.new(random: random, alpha: 0.0)
    allow(random).to receive(:rand).and_return(0.0)

    expect(crossover.crossover(parent1, parent2).chromosome).to eq(parent1.chromosome)
  end

  it "keeps identical parent coordinates unchanged" do
    expect(crossover.crossover(parent1, parent1).chromosome).to eq(parent1.chromosome)
  end

  it "produces independent offspring without changing either parent" do
    parent1.fitness = 42.0
    original = [parent1.chromosome.dup, parent2.chromosome.dup]

    child = crossover.crossover(parent1, parent2)
    child.chromosome[0] = 999.0
    child.fitness = -1.0

    expect(child).not_to be(parent1)
    expect(child).not_to be(parent2)
    expect([parent1.chromosome, parent2.chromosome]).to eq(original)
    expect(parent1.fitness).to eq(42.0)
  end

  it "reproduces offspring with an independent random generator using the same seed" do
    other = described_class.new(random: Random.new(123), alpha: 0.5)

    first = Array.new(5) { crossover.crossover(parent1, parent2).chromosome }
    second = Array.new(5) { other.crossover(parent1, parent2).chromosome }

    expect(first).to eq(second)
    expect(first.uniq.size).to be > 1
  end
end
