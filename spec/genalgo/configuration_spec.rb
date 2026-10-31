# frozen_string_literal: true

RSpec.describe Genalgo::Configuration do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1.0, 10.0], upper: [1.0, 20.0]) }
  let(:params) do
    { n_pop: 4, n_eval: 8, bounds: bounds, evaluation_function: ->(x) { x.sum { |gene| gene * gene } }, seed: 123 }
  end

  it "uses one immutable Bounds object and derives its dimension" do
    configuration = described_class.new(params)

    expect(configuration).to be_frozen
    expect(configuration.bounds).to be(bounds)
    expect(configuration.n_dim).to eq(2)
    expect(configuration.to_h).not_to have_key(:n_dim)
  end

  it "copies settings while sharing immutable bounds and the supplied callable" do
    configuration = described_class.new(params)
    params[:n_pop] = 100
    configuration.to_h[:bounds] = nil

    expect(configuration.n_pop).to eq(4)
    expect(configuration.bounds).to be(bounds)
    expect(configuration.evaluation_function).to be(params[:evaluation_function])
  end

  it "reports missing settings before execution" do
    expect { described_class.new(n_pop: 4) }.to raise_error(Genalgo::ConfigurationError) do |error|
      expect(error.context[:missing_parameters]).to contain_exactly(:n_eval, :bounds, :evaluation_function)
    end
  end

  {
    "non-integer population size" => { n_pop: 4.5 },
    "zero population size" => { n_pop: 0 },
    "insufficient BLX-alpha parents" => { n_pop: 1 },
    "insufficient Simplex parents" => { crossover: :simplex, n_pop: 2 },
    "non-integer budget" => { n_eval: 8.5 },
    "zero budget" => { n_eval: 0 },
    "insufficient budget" => { n_eval: 3 },
    "unknown crossover" => { crossover: :unknown },
    "false crossover" => { crossover: false },
    "non-integer seed" => { seed: "123" },
    "false seed" => { seed: false },
    "non-callable evaluator" => { evaluation_function: 1.0 },
    "bounds hash" => { bounds: { lower: [-1.0], upper: [1.0] } },
    "independently specified dimension" => { n_dim: 2 },
    "unknown setting" => { typo: 123 }
  }.each do |description, invalid_params|
    it "rejects #{description}" do
      expect { described_class.new(params.merge(invalid_params)) }.to raise_error(Genalgo::ConfigurationError)
    end
  end

  it "allows a budget covering only the initial population" do
    expect(described_class.new(params.merge(n_eval: 4)).n_eval).to eq(4)
  end

  it "accepts the minimum Simplex population derived from bounds" do
    configuration = described_class.new(params.merge(crossover: :simplex, n_pop: 3))

    expect(configuration.n_pop).to eq(configuration.bounds.n_dim + 1)
  end
end
