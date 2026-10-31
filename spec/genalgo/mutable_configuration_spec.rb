# frozen_string_literal: true

RSpec.describe Genalgo::MutableConfiguration do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1.0, 10.0], upper: [1.0, 20.0]) }
  let(:params) { { n_pop: 4, n_eval: 8, bounds: bounds, evaluation_function: lambda(&:sum), seed: 123 } }

  it "accepts partial input and validates when a snapshot is built" do
    input = described_class.new(n_pop: 4)
    input.bounds = :invalid

    expect(input).not_to be_complete
    expect { input.build }.to raise_error(Genalgo::ConfigurationError)
    params.each { |key, value| input.public_send("#{key}=", value) }

    expect(input).to be_complete
    expect(input.build.to_h).to include(params)
  end

  it "keeps its generated seed across edits and builds" do
    input = described_class.new(params.except(:seed))
    seed = input.seed
    input.n_eval = 10
    input.bounds = Genalgo::Bounds.new(lower: [0.0], upper: [1.0])

    expect(input.build.seed).to eq(seed)
    expect(input.build.seed).to eq(seed)
  end

  it "builds independent snapshots when the entire bounds object is replaced" do
    input = described_class.new(params)
    first = input.build
    input.bounds = Genalgo::Bounds.new(lower: [0.0, 10.0, 3.0], upper: [1.0, 20.0, 3.0])
    input.seed = 0
    second = input.build

    expect(first.bounds).to be(bounds)
    expect(first.n_dim).to eq(2)
    expect(first.seed).to eq(123)
    expect(second.bounds).to be(input.bounds)
    expect(second.n_dim).to eq(3)
    expect(second.seed).to eq(0)
    expect(first).to be_frozen
    expect(second).to be_frozen
    expect(input).not_to be_frozen
  end

  it "copies input settings and exported hashes" do
    input = described_class.new(params)
    params[:n_pop] = 100
    input.to_h[:bounds] = nil

    expect(input.build.n_pop).to eq(4)
    expect(input.bounds).to be(bounds)
  end

  it "allows invalid input to be corrected after a failed build" do
    input = described_class.new(params)
    input.bounds = :invalid
    expect { input.build }.to raise_error(Genalgo::ConfigurationError)

    input.bounds = bounds
    expect(input.build.bounds).to be(bounds)
  end

  it "rejects unknown settings when built instead of silently discarding them" do
    input = described_class.new(params.merge(typo: 123))

    expect { input.build }.to raise_error(Genalgo::ConfigurationError, /Unknown parameters: typo/)
  end

  it "generates a new seed when explicitly reset" do
    input = described_class.new(params)
    input.seed = nil

    expect(input.seed).to be_a(Integer)
    expect(input.seed).not_to eq(123)
    expect(input.build.seed).to eq(input.seed)
  end
end
