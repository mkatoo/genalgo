# frozen_string_literal: true

RSpec.describe Genalgo::Bounds do
  let(:params) { { lower: [-1.0, 10.0, 3.0], upper: [1.0, 20.0, 3.0] } }
  subject(:bounds) { described_class.new(**params) }

  it "derives its dimension from independent coordinate intervals" do
    expect(bounds.n_dim).to eq(3)
    expect(bounds.within_bounds?([0.0, 15.0, 3.0])).to be(true)
    expect(bounds.within_bounds?([0.0, 5.0, 3.0])).to be(false)
  end

  it "copies and freezes the input arrays" do
    original = bounds
    params[:lower][0] = -100.0
    params[:upper] << 100.0

    expect(original).to be_frozen
    expect(original.lower).to eq([-1.0, 10.0, 3.0])
    expect(original.upper).to eq([1.0, 20.0, 3.0])
    expect { original.lower[0] = 0.0 }.to raise_error(FrozenError)
    expect { original.upper << 1.0 }.to raise_error(FrozenError)
  end

  it "samples each coordinate from its interval, including fixed coordinates" do
    random = Random.new(123)
    20.times do
      chromosome = bounds.random_chromosome(random: random)
      expect(chromosome[0]).to be_between(-1.0, 1.0)
      expect(chromosome[1]).to be_between(10.0, 20.0)
      expect(chromosome[2]).to eq(3.0)
    end
  end

  it "clamps each coordinate without modifying the input" do
    chromosome = [-2.0, 30.0, 99.0]

    expect(bounds.clamp_chromosome(chromosome)).to eq([-1.0, 20.0, 3.0])
    expect(chromosome).to eq([-2.0, 30.0, 99.0])
  end

  {
    "missing lower array" => { lower: nil },
    "scalar lower bound" => { lower: -1.0 },
    "scalar upper bound" => { upper: 1.0 },
    "empty arrays" => { lower: [], upper: [] },
    "different array lengths" => { upper: [1.0] },
    "non-numeric coordinate" => { lower: [-1.0, "10", 3.0] },
    "NaN coordinate" => { upper: [1.0, Float::NAN, 3.0] },
    "infinite coordinate" => { lower: [-Float::INFINITY, 10.0, 3.0] },
    "complex coordinate" => { upper: [1.0, Complex(20, 1), 3.0] },
    "reversed interval" => { lower: [-1.0, 21.0, 3.0] }
  }.each do |description, invalid_params|
    it "rejects #{description}" do
      expect { described_class.new(**params, **invalid_params) }.to raise_error(Genalgo::ConfigurationError)
    end
  end

  [nil, "abc", [0.0], [0.0, 15.0, 3.0, 4.0], [0.0, nil, 3.0], [0.0, Float::NAN, 3.0]].each do |chromosome|
    it "rejects a malformed chromosome #{chromosome.inspect}" do
      expect(bounds.within_bounds?(chromosome)).to be(false)
      expect { bounds.clamp_chromosome(chromosome) }.to raise_error(ArgumentError)
    end
  end
end
