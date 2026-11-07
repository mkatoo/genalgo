# frozen_string_literal: true

RSpec.describe Genalgo::Individual do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1, 10, 3], upper: [1, 20, 3]) }

  [[0, 15, 3], [0.0, 15.0, 3.0]].each do |genes|
    it "owns an immutable chromosome without freezing caller input #{genes.inspect}" do
      chromosome = genes.dup
      individual = described_class.new(bounds: bounds, chromosome: chromosome, fitness: -2)
      chromosome[0] = 99

      expect(individual).to be_frozen
      expect(individual.bounds).to be(bounds)
      expect(individual.chromosome).to eq([0.0, 15.0, 3.0])
      expect(individual.chromosome).to all(be_a(Float))
      expect(individual.fitness).to eq(-2.0)
      expect { individual.chromosome[0] = 99 }.to raise_error(FrozenError)
      expect(individual).not_to respond_to(:chromosome=, :fitness=)
    end
  end

  it "shares a frozen Float chromosome" do
    chromosome = [0.0, 15.0, 3.0].freeze
    individual = described_class.new(bounds: bounds, chromosome: chromosome, fitness: 0)

    expect(individual.chromosome).to be(chromosome)
  end

  it "copies frozen chromosomes with other numeric types into Float coordinates" do
    chromosome = [0, Rational(31, 2), 3.0].freeze
    individual = described_class.new(bounds: bounds, chromosome: chromosome, fitness: 0)

    expect(individual.chromosome).not_to be(chromosome)
    expect(individual.chromosome).to eq([0.0, 15.5, 3.0])
    expect(individual.chromosome).to all(be_a(Float))
    expect(individual.chromosome).to be_frozen
  end

  [nil, "1", Float::NAN, Float::INFINITY, -Float::INFINITY, Complex(1, 1), 10**400].each do |fitness|
    it "rejects invalid fitness #{fitness.inspect}" do
      expect { described_class.new(bounds: bounds, chromosome: [0, 15, 3], fitness: fitness) }
        .to raise_error(ArgumentError)
    end
  end

  [[0.0], [2.0, 15.0, 3.0], [0, nil, 3], [0.0, Float::NAN, 3.0]].each do |chromosome|
    it "rejects an invalid or out-of-bounds chromosome #{chromosome.inspect}" do
      expect { described_class.new(bounds: bounds, chromosome: chromosome, fitness: 0) }.to raise_error(ArgumentError)
      chromosome.freeze
      expect { described_class.new(bounds: bounds, chromosome: chromosome, fitness: 0) }.to raise_error(ArgumentError)
    end
  end
end
