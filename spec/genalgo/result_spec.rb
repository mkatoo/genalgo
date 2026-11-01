# frozen_string_literal: true

RSpec.describe Genalgo::Result do
  it "copies result collections and shares immutable individuals with history" do
    configuration = Genalgo::Configuration.new(bounds: Genalgo::Bounds.new(lower: [-1], upper: [1]),
                                               population_size: 2, max_evaluations: 2, seed: 0)
    best = Genalgo::Individual.new(bounds: configuration.bounds, chromosome: [0], fitness: 0)
    worst = Genalgo::Individual.new(bounds: configuration.bounds, chromosome: [1], fitness: 1)
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
end
