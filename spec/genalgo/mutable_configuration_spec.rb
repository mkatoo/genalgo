# frozen_string_literal: true

RSpec.describe Genalgo::MutableConfiguration do
  let(:params) do
    {
      n_pop: 4, n_dim: 2, n_eval: 8, lower_limit: -1.0, upper_limit: 1.0,
      evaluation_function: lambda(&:sum), seed: 123
    }
  end

  it "accepts partial input and validates only when a snapshot is built" do
    input = described_class.new(n_pop: 4)
    input.n_dim = 0

    expect(input).not_to be_complete
    expect { input.build }.to raise_error(Genalgo::ConfigurationError)

    params.each { |key, value| input.public_send("#{key}=", value) }

    expect(input).to be_complete
    expect(input.build.to_h).to include(params)
  end

  it "keeps the generated seed across edits and builds" do
    input = described_class.new(params.except(:seed))
    original_seed = input.seed
    input.n_eval = 10
    input.upper_limit = 2.0

    expect(input.seed).to eq(original_seed)
    expect(input.build.seed).to eq(original_seed)
    expect(input.build.seed).to eq(original_seed)
  end

  it "builds independent snapshots while keeping the input editable" do
    input = described_class.new(params)
    first = input.build
    input.n_dim = 3
    input.upper_limit = 10.0
    input.seed = 0
    second = input.build

    expect(first.to_h).to include(n_dim: 2, upper_limit: 1.0, seed: 123)
    expect(first.bounds_object.random_chromosome.size).to eq(2)
    expect(second.to_h).to include(n_dim: 3, upper_limit: 10.0, seed: 0)
    expect(second.bounds_object.random_chromosome.size).to eq(3)
    expect(first).to be_frozen
    expect(second).to be_frozen
    expect(input).not_to be_frozen
  end

  it "does not share its input hash or exported hash with callers" do
    input = described_class.new(params)
    params[:n_pop] = 100
    input.to_h[:n_eval] = 1

    expect(input.build.to_h).to include(n_pop: 4, n_eval: 8)
  end

  it "allows invalid edits to be corrected after a failed build" do
    input = described_class.new(params)
    input.upper_limit = -2.0
    expect { input.build }.to raise_error(Genalgo::ConfigurationError)

    input.upper_limit = 2.0
    expect(input.build.upper_limit).to eq(2.0)
  end
end
