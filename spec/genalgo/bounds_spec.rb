# frozen_string_literal: true

RSpec.describe Genalgo::Bounds do
  let(:params) { { n_dim: 2, lower_limit: -1.0, upper_limit: 1.0 } }

  it "is immutable and still supports sampling and clamping" do
    bounds = described_class.new(**params)

    expect(bounds).to be_frozen
    expect(bounds.within_bounds?(bounds.random_chromosome)).to be(true)
    expect(bounds.clamp_chromosome([-2.0, 2.0])).to eq([-1.0, 1.0])
  end

  {
    "missing dimension" => { n_dim: nil },
    "non-integer dimension" => { n_dim: 2.5 },
    "zero dimension" => { n_dim: 0 },
    "negative dimension" => { n_dim: -1 },
    "missing lower limit" => { lower_limit: nil },
    "missing upper limit" => { upper_limit: nil },
    "non-numeric lower limit" => { lower_limit: "-1" },
    "non-numeric upper limit" => { upper_limit: "1" },
    "reversed limits" => { lower_limit: 2.0 },
    "NaN lower limit" => { lower_limit: Float::NAN },
    "NaN upper limit" => { upper_limit: Float::NAN },
    "infinite lower limit" => { lower_limit: -Float::INFINITY },
    "infinite upper limit" => { upper_limit: Float::INFINITY },
    "complex limit" => { upper_limit: Complex(1, 1) }
  }.each do |description, invalid_params|
    it "rejects #{description} through every initialization path" do
      values = params.merge(invalid_params)
      constructors = [
        -> { described_class.new(**values) },
        -> { Genalgo::Individual.new(**values) },
        -> { Genalgo::Population.new(n_pop: 4, **values) },
        -> { Genalgo::Configuration.new(values.merge(n_pop: 4, n_eval: 8, evaluation_function: lambda(&:sum))) }
      ]

      constructors.each do |construct|
        expect(&construct).to raise_error(Genalgo::ConfigurationError)
      end
    end
  end
end
