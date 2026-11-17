# frozen_string_literal: true

RSpec.describe Genalgo::Result do
  it "copies result collections and shares immutable individuals with history" do
    configuration = Genalgo::Configuration.new(bounds: Genalgo::Bounds.new(lower: [-1], upper: [1]),
                                               population_size: 2, max_evaluations: 2, seed: 0)
    evaluator = Genalgo::Evaluator.new(bounds: configuration.bounds, max_evaluations: 2) { |genes| genes.first**2 }
    best = evaluator.evaluate([0])
    worst = evaluator.evaluate([1])
    population = [worst, best]
    history = [described_class::Snapshot.new(best_individual: best, evaluations: 2)]
    result = described_class.new(configuration: configuration, population: population, history: history, evaluations: 2)
    population.clear
    history.clear

    expect(result.population).to eq([worst, best])
    expect(result.best_individual).to be(best)
    expect(result.history.last.best_individual).to be(best)
    expect(result.seed).to eq(0)
    expect(result).to be_frozen
    expect(result.population).to be_frozen
    expect(result.history).to be_frozen
    expect(result.history.first).to be_frozen
  end

  it "preserves the population's chosen best when tied individuals change slots" do
    configuration = Genalgo::Configuration.new(bounds: Genalgo::Bounds.new(lower: [-1], upper: [1]),
                                               population_size: 2, max_evaluations: 4, seed: 0)
    evaluator = Genalgo::Evaluator.new(bounds: configuration.bounds, max_evaluations: 2) { 1 }
    first = evaluator.evaluate([-1])
    second = evaluator.evaluate([1])
    population = Genalgo::Population.new([first, second])
    population.replace([0, 1], [second, first])
    history = [described_class::Snapshot.new(best_individual: population.best_individual, evaluations: 4)]
    result = described_class.new(configuration: configuration, population: population, history: history, evaluations: 4)
    population.replace([0, 1], [second, second])

    expect(result.population).to eq([second, first])
    expect(result.best_individual).to be(first)
    expect(result.history.last.best_individual).to be(result.best_individual)
  end
end
