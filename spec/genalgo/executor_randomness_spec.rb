# frozen_string_literal: true

RSpec.describe Genalgo::Executor, "randomness isolation" do
  let(:params) do
    {
      n_pop: 6, n_eval: 20, bounds: Genalgo::Bounds.new(lower: [-1.0, -1.0], upper: [1.0, 1.0]),
      evaluation_function: ->(chromosome) { chromosome.sum { |gene| gene * gene } }, seed: 14
    }
  end

  after { Random.srand(RSpec.configuration.seed) }

  %i[blx_alpha simplex].each do |crossover|
    context "with #{crossover} crossover" do
      let(:settings) { params.merge(crossover: crossover) }

      it "starts a fresh random stream for every execution with the same seed" do
        expect(Random).to receive(:new).with(settings[:seed]).twice.and_call_original
        executor = described_class.new(settings)
        executor.execute
        expected = snapshot(executor)

        Random.srand(999)
        10.times { Random.rand }
        executor.execute

        expect(snapshot(executor)).to eq(expected)
      end

      it "keeps its random stream independent of global random use during evaluation" do
        baseline = described_class.new(settings)
        baseline.execute
        calls = 0
        executor = described_class.new(settings.merge(evaluation_function: lambda do |chromosome|
          calls += 1
          Random.srand(calls)
          3.times { Random.rand }
          params[:evaluation_function].call(chromosome)
        end))

        executor.execute

        expect(calls).to eq(settings[:n_eval])
        expect(snapshot(executor)).to eq(snapshot(baseline))
      end

      %i[initialization evolution].each do |phase|
        it "keeps its random stream independent of another executor started during #{phase}" do
          baseline = described_class.new(settings)
          baseline.execute
          nested = described_class.new(settings.merge(
                                         n_pop: 3, n_eval: 7, seed: 999,
                                         bounds: Genalgo::Bounds.new(lower: [-1.0], upper: [1.0]),
                                         crossover: crossover == :simplex ? :blx_alpha : :simplex
                                       ))
          calls = 0
          nested_at = phase == :initialization ? 1 : settings[:n_pop] + 1
          executor = described_class.new(settings.merge(evaluation_function: lambda do |chromosome|
            calls += 1
            nested.execute if calls == nested_at
            params[:evaluation_function].call(chromosome)
          end))

          executor.execute

          expect(calls).to eq(settings[:n_eval])
          expect(nested.history.last.evaluations).to eq(7)
          expect(snapshot(executor)).to eq(snapshot(baseline))
        end
      end

      it "leaves the global random stream unchanged" do
        expected_random = Random.new(812)
        Random.srand(812)
        expect(Random.rand).to eq(expected_random.rand)

        described_class.new(settings).execute

        expect(Array.new(5) { Random.rand }).to eq(Array.new(5) { expected_random.rand })
      end
    end
  end

  private

  def snapshot(executor)
    {
      history: executor.history.map do |entry|
        [entry.evaluations, entry.best_individual.chromosome.dup, entry.best_individual.fitness]
      end,
      population: executor.population.map { |individual| [individual.chromosome.dup, individual.fitness] }
    }
  end
end
