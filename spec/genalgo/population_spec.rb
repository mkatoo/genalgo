# frozen_string_literal: true

RSpec.describe Genalgo::Population do
  let(:bounds) { Genalgo::Bounds.new(lower: [-10], upper: [10]) }
  let(:individuals) { [1, 2, 3, 4].map { |gene| individual(gene) } }
  subject(:population) { described_class.new(individuals) }

  it "copies the slots while sharing immutable individuals" do
    original = population.first
    individuals.clear

    expect(population.size).to eq(4)
    expect(population.first).to be(original)
    expect(population.best_individual).to be(original)
  end

  it "samples distinct valid indices reproducibly" do
    first = population.sample_indices(4, random: Random.new(123))
    second = population.sample_indices(4, random: Random.new(123))

    expect(first.sort).to eq([0, 1, 2, 3])
    expect(first).to eq(second)
    expect(population.to_a).to eq(individuals)
  end

  [0, 5, 1.5].each do |count|
    it "rejects an invalid sample size #{count}" do
      expect { population.sample_indices(count, random: Random.new(123)) }.to raise_error(Genalgo::PopulationError)
    end
  end

  it "replaces only the specified slots and updates the best" do
    before = population.to_a
    child = individual(0)
    population.replace([1, 3], [child, before[1]])

    expect(population.to_a).to eq([before[0], child, before[2], before[1]])
    expect(population.best_individual).to be(child)
  end

  it "recomputes the best if a caller removes it" do
    population.replace([0], [individual(9)])

    expect(population.best_individual.fitness).to eq(4.0)
  end

  it "keeps the best when an elite is moved to another slot" do
    best = population.best_individual
    population.replace([0, 3], [individual(9), best])

    expect(population.best_individual).to be(best)
  end

  it "keeps the current best on a tie while it remains in the population" do
    best = population.best_individual
    tied = individual(-1)
    population.replace([0, 1], [tied, best])

    expect(population.best_individual).to be(best)

    population.replace([1], [individual(9)])

    expect(population.best_individual).to be(tied)
  end

  [[-1], [4], [0, 0], [1.5]].each do |indices|
    it "rejects invalid replacement indices #{indices.inspect} atomically" do
      before = population.to_a
      expect { population.replace(indices, indices.map { individual(0) }) }.to raise_error(Genalgo::PopulationError)
      expect(population.to_a).to eq(before)
    end
  end

  it "rejects a mismatched replacement length and different bounds atomically" do
    before = population.to_a
    other = Genalgo::Individual.new(bounds: Genalgo::Bounds.new(lower: [-1], upper: [1]), chromosome: [0], fitness: 0)

    expect { population.replace([0], []) }.to raise_error(Genalgo::PopulationError)
    expect { population.replace([0, 1], [individual(0), other]) }.to raise_error(Genalgo::PopulationError)
    expect(population.to_a).to eq(before)
  end

  [[], [nil]].each do |values|
    it "rejects an invalid initial population #{values.inspect}" do
      expect { described_class.new(values) }.to raise_error(Genalgo::PopulationError)
    end
  end

  private

  def individual(gene)
    Genalgo::Individual.new(bounds: bounds, chromosome: [gene], fitness: gene * gene)
  end
end
