# frozen_string_literal: true

RSpec.describe Genalgo::Configuration do
  let(:params) do
    {
      n_pop: 4, n_dim: 2, n_eval: 8, lower_limit: -1.0, upper_limit: 1.0,
      evaluation_function: ->(x) { x.sum { |value| value * value } }, seed: 123
    }
  end

  it "provides immutable bounds immediately after construction" do
    configuration = described_class.new(params)

    expect(configuration).to be_frozen
    expect(configuration.bounds).to eq(upper: 1.0, lower: -1.0)
    expect(configuration.bounds).to be_frozen
    expect(configuration.bounds_object).to be_frozen
    expect(configuration.bounds_object.within_bounds?([0.0, 1.0])).to be(true)
    expect { configuration.bounds[:upper] = 10.0 }.to raise_error(FrozenError)
  end

  it "does not change when the input or exported hash is edited" do
    configuration = described_class.new(params)
    params[:n_pop] = 100
    configuration.to_h[:lower_limit] = -100.0

    expect(configuration.n_pop).to eq(4)
    expect(configuration.lower_limit).to eq(-1.0)
  end

  it "reports missing parameters when the configuration is constructed" do
    expect { described_class.new(n_pop: 4) }.to raise_error(Genalgo::ConfigurationError) do |error|
      expect(error.context[:missing_parameters]).to contain_exactly(
        :n_dim, :n_eval, :upper_limit, :lower_limit, :evaluation_function
      )
    end
  end

  {
    "non-integer population size" => { n_pop: 4.5 },
    "zero population size" => { n_pop: 0 },
    "insufficient BLX-alpha parents" => { n_pop: 1 },
    "insufficient Simplex parents" => { crossover: :simplex, n_pop: 2 },
    "non-integer evaluation budget" => { n_eval: 8.5 },
    "zero evaluation budget" => { n_eval: 0 },
    "budget below the initial population size" => { n_eval: 3 },
    "unknown crossover" => { crossover: :unknown },
    "non-integer seed" => { seed: "123" },
    "non-callable evaluation function" => { evaluation_function: 1.0 }
  }.each do |description, invalid_params|
    it "rejects #{description} before execution" do
      expect { described_class.new(params.merge(invalid_params)) }.to raise_error(Genalgo::ConfigurationError)
    end
  end

  it "allows a budget covering only the initial population" do
    configuration = described_class.build(params.merge(n_eval: 4))

    expect(configuration.n_eval).to eq(4)
    expect(configuration).to be_frozen
  end

  it "allows equal bounds consistently with individual initialization" do
    configuration = described_class.new(params.merge(lower_limit: 1.0, upper_limit: 1.0))

    expect(configuration.bounds_object.random_chromosome).to eq([1.0, 1.0])
  end

  it "accepts the minimum number of Simplex parents" do
    configuration = described_class.new(params.merge(crossover: :simplex, n_pop: 3))

    expect(configuration.n_pop).to eq(3)
  end
end
