# frozen_string_literal: true

RSpec.describe Genalgo::Executor, "execution behavior" do
  # Recorded before refactoring; update only when an algorithm change is intentional.
  {
    blx_alpha: [
      [4, [0.026233424535774263, -0.36343115025580275], 0.13277039353913003],
      [6, [-0.28751074375317737, 0.15905266234555748], 0.10796017717271514],
      [8, [0.027120792722969578, -0.19805657958684397], 0.03996194611556214],
      [10, [0.02699012434676568, -0.08181449027644255], 0.007422077631447986],
      [12, [0.02701546726242263, -0.06245269340459442], 0.0046301743848953]
    ],
    simplex: [
      [4, [0.026233424535774263, -0.36343115025580275], 0.13277039353913003],
      [6, [0.11794745565569409, -0.32027127703889935], 0.11648529319177935],
      [8, [-0.10238424103483873, -0.021503994788446334], 0.010944954604141481],
      [10, [-0.10238424103483873, -0.021503994788446334], 0.010944954604141481],
      [12, [-0.10238424103483873, -0.021503994788446334], 0.010944954604141481]
    ]
  }.each do |crossover, expected_history|
    context "with #{crossover} crossover" do
      let(:params) do
        {
          n_pop: 4, n_eval: 12, bounds: Genalgo::Bounds.new(lower: [-1.0, -1.0], upper: [1.0, 1.0]),
          evaluation_function: ->(chromosome) { chromosome.sum { |gene| gene * gene } },
          seed: 14, crossover: crossover
        }
      end

      it "matches the recorded chromosomes, fitness values, and evaluation counts" do
        executor = described_class.new(params)

        executor.execute

        expect(executor.history.size).to eq(expected_history.size)
        executor.history.zip(expected_history).each do |entry, (evaluations, chromosome, fitness)|
          expect(entry.evaluations).to eq(evaluations)
          expect(entry.best_individual.chromosome).to match(chromosome.map { |gene| be_within(1e-12).of(gene) })
          expect(entry.best_individual.fitness).to be_within(1e-12).of(fitness)
        end
      end

      [4, 5, 12, 13].each do |budget|
        it "records the actual evaluation count without exceeding a budget of #{budget}" do
          calls = 0
          executor = described_class.new(params.merge(n_eval: budget, evaluation_function: lambda do |chromosome|
            calls += 1
            params[:evaluation_function].call(chromosome)
          end))

          executor.execute

          expected_counts = (4..budget).step(2).to_a
          expect(calls).to eq(expected_counts.last)
          expect(executor.history.map(&:evaluations)).to eq(expected_counts)
          expect(executor.population.size).to eq(4)
        end
      end

      it "keeps every coordinate fixed when the lower and upper bounds are equal" do
        executor = described_class.new(params.merge(bounds: Genalgo::Bounds.new(lower: [0.5, 0.5], upper: [0.5, 0.5])))

        executor.execute

        expect(executor.population.map(&:chromosome)).to all(eq([0.5, 0.5]))
        expect(executor.population.map(&:fitness)).to all(eq(0.5))
        expect(executor.history.map(&:evaluations)).to eq([4, 6, 8, 10, 12])
      end

      it "initializes and evolves within separate coordinate intervals and a fixed coordinate" do
        bounds = Genalgo::Bounds.new(lower: [-1.0, 10.0, 3.0], upper: [1.0, 20.0, 3.0])
        executor = described_class.new(params.merge(bounds: bounds))

        executor.execute

        expect(executor.execution_configuration.n_dim).to eq(3)
        expect(executor.population.size).to eq(4)
        executor.population.each do |individual|
          expect(individual.bounds).to be(bounds)
          expect(individual.chromosome[0]).to be_between(-1.0, 1.0)
          expect(individual.chromosome[1]).to be_between(10.0, 20.0)
          expect(individual.chromosome[2]).to eq(3.0)
        end
        executor.history.each do |entry|
          expect(entry.best_individual).to be_within_bounds
          expect(entry.best_individual.chromosome[2]).to eq(3.0)
          expected_fitness = params[:evaluation_function].call(entry.best_individual.chromosome)
          expect(entry.best_individual.fitness).to eq(expected_fitness)
        end
        expect(executor.history.last.evaluations).to eq(12)
      end

      it "keeps recorded history independent of subsequent population edits" do
        executor = described_class.new(params)
        executor.execute
        recorded = executor.history.map do |entry|
          [entry.best_individual.chromosome.dup, entry.best_individual.fitness]
        end

        executor.population.each do |individual|
          individual.chromosome.fill(1.0)
          individual.fitness = -1.0
        end

        actual = executor.history.map { |entry| [entry.best_individual.chromosome, entry.best_individual.fitness] }
        expect(actual).to eq(recorded)
      end
    end
  end
end
