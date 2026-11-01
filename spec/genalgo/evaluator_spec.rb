# frozen_string_literal: true

RSpec.describe Genalgo::Evaluator do
  let(:bounds) { Genalgo::Bounds.new(lower: [-1, 10], upper: [1, 20]) }

  it "evaluates a frozen, clamped copy and counts actual calls" do
    source = [-2, 30]
    seen = nil
    evaluator = described_class.new(bounds: bounds, max_evaluations: 2) do |chromosome|
      seen = chromosome
      chromosome.sum
    end

    individual = evaluator.evaluate(source)

    expect(seen).to be_frozen
    expect(seen).not_to be(source)
    expect(source).to eq([-2, 30])
    expect(individual.chromosome).to eq([-1.0, 20.0])
    expect(individual.fitness).to eq(19.0)
    expect(evaluator.evaluations).to eq(1)
    expect(evaluator.remaining).to eq(1)
  end

  it "does not invoke the objective after the budget is exhausted" do
    calls = 0
    evaluator = described_class.new(bounds: bounds, max_evaluations: 1) { calls += 1 }
    evaluator.evaluate([0, 15])

    expect { evaluator.evaluate([0, 15]) }.to raise_error(Genalgo::EvaluationError, /budget/)
    expect(calls).to eq(1)
    expect(evaluator.evaluations).to eq(1)
  end

  [nil, "1", Float::NAN, Float::INFINITY, Complex(1, 1)].each do |value|
    it "reports invalid objective output #{value.inspect} with its evaluation number" do
      evaluator = described_class.new(bounds: bounds, max_evaluations: 1) { value }

      expect { evaluator.evaluate([0, 15]) }.to raise_error(Genalgo::EvaluationError) do |error|
        expect(error.cause).to be_a(ArgumentError)
        expect(error.context).to include(evaluations: 1, chromosome: [0.0, 15.0])
      end
      expect(evaluator.evaluations).to eq(1)
    end
  end

  it "preserves objective exceptions and their backtraces as the cause" do
    failure = RuntimeError.new("objective failure")
    evaluator = described_class.new(bounds: bounds, max_evaluations: 2) { raise failure }

    expect { evaluator.evaluate([0, 15]) }.to raise_error(Genalgo::EvaluationError) do |error|
      expect(error.cause).to be(failure)
      expect(error.cause.backtrace.first).to include("evaluator_spec.rb")
      expect(error.context[:evaluations]).to eq(1)
    end
  end

  it "reports attempted chromosome mutation without changing the caller's data" do
    source = [0, 15]
    evaluator = described_class.new(bounds: bounds, max_evaluations: 1) { |genes| genes[0] = 99 }

    expect { evaluator.evaluate(source) }.to raise_error(Genalgo::EvaluationError) do |error|
      expect(error.cause).to be_a(FrozenError)
    end
    expect(source).to eq([0, 15])
  end

  it "requires an objective before any evaluation" do
    expect { described_class.new(bounds: bounds, max_evaluations: 1) }.to raise_error(ArgumentError, /objective/)
  end
end
