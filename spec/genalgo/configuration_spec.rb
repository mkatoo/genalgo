# frozen_string_literal: true

RSpec.describe Genalgo::Configuration do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1.0, 10.0], upper: [1.0, 20.0]) }
  let(:params) { { population_size: 4, max_evaluations: 8, bounds: bounds, seed: 123 } }

  it "validates and freezes settings with an immutable default crossover" do
    configuration = described_class.new(**params)

    expect(configuration).to be_frozen
    expect(configuration.crossover).to be_a(Genalgo::Crossovers::BlxAlpha)
    expect(configuration.crossover).to be_frozen
    expect(configuration.bounds).to be(bounds)
  end

  it "creates independent settings while preserving the seed and unchanged immutable values" do
    original = described_class.new(**params.except(:seed))
    changed = original.with(max_evaluations: 20)
    changed.to_h[:population_size] = 100

    expect(changed).to be_frozen
    expect(changed.seed).to eq(original.seed)
    expect(changed.bounds).to be(original.bounds)
    expect(changed.crossover).to be(original.crossover)
    expect(original.max_evaluations).to eq(8)
    expect(changed.max_evaluations).to eq(20)
    expect(changed.population_size).to eq(4)
    expect(original.with(seed: nil).seed).to be_a(Integer)
    expect(original.with(seed: 0).seed).to eq(0)
  end

  {
    "non-integer population" => { population_size: 4.5 },
    "zero population" => { population_size: 0 },
    "negative population" => { population_size: -1 },
    "too few BLX-alpha parents" => { population_size: 1 },
    "too few Simplex parents" => { crossover: Genalgo::Crossovers::Simplex.new, population_size: 2 },
    "non-integer budget" => { max_evaluations: 8.5 },
    "zero budget" => { max_evaluations: 0 },
    "insufficient budget" => { max_evaluations: 3 },
    "invalid bounds" => { bounds: {} },
    "invalid seed" => { seed: "123" },
    "false seed" => { seed: false },
    "symbol crossover" => { crossover: :simplex },
    "mutable crossover" => { crossover: Genalgo::Crossovers::Simplex.new.dup }
  }.each do |description, changes|
    it "rejects #{description} when constructed" do
      expect { described_class.new(**params, **changes) }.to raise_error(Genalgo::ConfigurationError)
    end
  end

  it "rejects missing and unknown keywords" do
    expect { described_class.new(population_size: 4) }.to raise_error(ArgumentError)
    expect { described_class.new(**params, typo: true) }.to raise_error(ArgumentError)
  end

  it "accepts the minimum Simplex population and an initialization-only budget" do
    configuration = described_class.new(**params, population_size: 3, max_evaluations: 3,
                                                  crossover: Genalgo::Crossovers::Simplex.new)

    expect(configuration.population_size).to eq(configuration.bounds.dimension + 1)
  end
end
