# frozen_string_literal: true

RSpec.describe Genalgo::Individual do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1, 10, 3], upper: [1, 20, 3]) }
  let(:chromosome) { Genalgo.const_get(:BoundedChromosome).new(bounds: bounds, chromosome: [0, 15, 3]) }

  it "shares normalized coordinates and derives their bounds" do
    individual = described_class.new(chromosome: chromosome, fitness: -2)

    expect(individual).to be_frozen
    expect(individual.bounds).to be(bounds)
    expect(individual.chromosome).to be(chromosome.coordinates)
    expect(individual.fitness).to eq(-2.0)
    expect(individual.fitness).to be_a(Float)
    expect { individual.chromosome[0] = 99 }.to raise_error(FrozenError)
    expect(individual).not_to respond_to(:chromosome=, :fitness=)
  end

  it "rejects a raw chromosome even when it is a frozen Float array within bounds" do
    expect { described_class.new(chromosome: [0.0, 15.0, 3.0].freeze, fitness: 0) }
      .to raise_error(ArgumentError, /normalized chromosome/)
  end

  [nil, "1", Float::NAN, Float::INFINITY, -Float::INFINITY, Complex(1, 1), 10**400].each do |fitness|
    it "rejects invalid fitness #{fitness.inspect}" do
      expect { described_class.new(chromosome: chromosome, fitness: fitness) }
        .to raise_error(ArgumentError)
    end
  end
end
