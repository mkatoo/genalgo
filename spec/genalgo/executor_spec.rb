# frozen_string_literal: true

RSpec.describe Genalgo::Executor do
  let(:default_params) do
    {
      n_pop: 10,
      n_dim: 3,
      n_eval: 50,
      evaluation_function: ->(chromosome) { chromosome.sum.abs },
      upper_limit: 5.0,
      lower_limit: -5.0,
      crossover: :blx_alpha,
      seed: 12_345
    }
  end

  describe "#initialize" do
    context "with all parameters" do
      subject(:executor) { described_class.new(default_params) }

      it "sets all provided parameters" do
        expect(executor.n_pop).to eq(10)
        expect(executor.n_dim).to eq(3)
        expect(executor.n_eval).to eq(50)
        expect(executor.upper_limit).to eq(5.0)
        expect(executor.lower_limit).to eq(-5.0)
        expect(executor.crossover).to eq(:blx_alpha)
        expect(executor.seed).to eq(12_345)
        expect(executor.evaluation_function).to be_a(Proc)
      end
    end

    context "with minimal parameters" do
      subject(:executor) { described_class.new }

      it "creates executor with nil values" do
        expect(executor.n_pop).to be_nil
        expect(executor.n_dim).to be_nil
        expect(executor.n_eval).to be_nil
        expect(executor.evaluation_function).to be_nil
      end

      it "sets default crossover to :blx_alpha" do
        expect(executor.crossover).to eq(:blx_alpha)
      end

      it "generates a random seed" do
        expect(executor.seed).to be_a(Integer)
        expect(executor.seed).to be_positive
      end
    end

    context "with partial parameters" do
      let(:partial_params) { { n_pop: 20, crossover: :simplex } }
      subject(:executor) { described_class.new(partial_params) }

      it "sets provided parameters and leaves others nil" do
        expect(executor.n_pop).to eq(20)
        expect(executor.crossover).to eq(:simplex)
        expect(executor.n_dim).to be_nil
      end
    end
  end

  describe "attribute accessors" do
    subject(:executor) { described_class.new }

    it "allows setting and getting n_pop" do
      executor.n_pop = 50
      expect(executor.n_pop).to eq(50)
    end

    it "allows setting and getting n_dim" do
      executor.n_dim = 5
      expect(executor.n_dim).to eq(5)
    end

    it "allows setting and getting n_eval" do
      executor.n_eval = 1000
      expect(executor.n_eval).to eq(1000)
    end

    it "allows setting and getting evaluation_function" do
      func = ->(x) { x.map(&:abs).sum }
      executor.evaluation_function = func
      expect(executor.evaluation_function).to eq(func)
    end

    it "allows setting and getting bounds" do
      executor.upper_limit = 10.0
      executor.lower_limit = -10.0
      expect(executor.upper_limit).to eq(10.0)
      expect(executor.lower_limit).to eq(-10.0)
    end

    it "allows setting and getting crossover type" do
      executor.crossover = :simplex
      expect(executor.crossover).to eq(:simplex)
    end

    it "allows setting and getting seed" do
      executor.seed = 54_321
      expect(executor.seed).to eq(54_321)
    end
  end

  describe "read-only attributes" do
    subject(:executor) { described_class.new(default_params) }

    it "provides read access to population after execution" do
      executor.execute
      expect(executor.population).to be_a(Genalgo::Population)
      expect(executor.population.size).to eq(10)
    end

    it "provides read access to history after execution" do
      executor.execute
      expect(executor.history).to be_a(Genalgo::History)
      expect(executor.history.size).to be > 0
    end

    it "prevents write access to population" do
      expect(executor).not_to respond_to(:population=)
    end

    it "prevents write access to history" do
      expect(executor).not_to respond_to(:history=)
    end
  end

  describe "#execute" do
    subject(:executor) { described_class.new(default_params) }

    context "with valid configuration" do
      it "completes execution without error" do
        expect { executor.execute }.not_to raise_error
      end

      it "creates a population" do
        executor.execute
        expect(executor.population).to be_a(Genalgo::Population)
        expect(executor.population.size).to eq(10)
      end

      it "creates history" do
        executor.execute
        expect(executor.history).to be_a(Genalgo::History)
        expect(executor.history.size).to be > 0
      end

      it "evaluates all individuals" do
        executor.execute
        executor.population.each do |individual|
          expect(individual.fitness).not_to be_nil
          expect(individual.fitness).to be_a(Numeric)
        end
      end

      it "respects the evaluation budget" do
        executor.execute
        # Should not exceed n_eval (50) evaluations
        expect(executor.history.last.evaluations).to be <= 50
      end

      it "tracks progress in history" do
        executor.execute
        # History should show progression
        evaluations = executor.history.map(&:evaluations)
        expect(evaluations).to eq(evaluations.sort)
        expect(evaluations.first).to eq(10) # Initial population
      end
    end

    context "with different crossover types" do
      let(:simplex_executor) do
        params = default_params.merge(crossover: :simplex)
        described_class.new(params)
      end

      it "works with BLX-alpha crossover" do
        expect { executor.execute }.not_to raise_error
      end

      it "works with Simplex crossover" do
        expect { simplex_executor.execute }.not_to raise_error
      end
    end

    context "with seed for reproducibility" do
      let(:executor1) { described_class.new(default_params.merge(seed: 99_999)) }
      let(:executor2) { described_class.new(default_params.merge(seed: 99_999)) }

      it "produces reproducible results with same seed" do
        executor1.execute
        executor2.execute

        history1 = executor1.history.map { |data| data.best_individual.fitness }
        history2 = executor2.history.map { |data| data.best_individual.fitness }

        expect(history1).to eq(history2)
      end
    end

    context "with insufficient parameters" do
      let(:incomplete_executor) { described_class.new(n_pop: 10) }

      it "raises error with incomplete configuration" do
        expect { incomplete_executor.execute }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#best_individual" do
    subject(:executor) { described_class.new(default_params) }

    context "before execution" do
      it "returns nil before execution" do
        expect(executor.best_individual).to be_nil
      end
    end

    context "after execution" do
      before { executor.execute }

      it "returns an Individual instance" do
        expect(executor.best_individual).to be_a(Genalgo::Individual)
      end

      it "returns the individual with the best fitness" do
        best = executor.best_individual
        executor.population.each do |individual|
          expect(best.fitness).to be <= individual.fitness
        end
      end

      it "matches the best individual from history" do
        history_best = executor.history.last.best_individual
        current_best = executor.best_individual

        expect(current_best.fitness).to eq(history_best.fitness)
        expect(current_best.chromosome).to eq(history_best.chromosome)
      end
    end
  end

  describe "MGG integration" do
    subject(:executor) { described_class.new(default_params) }

    it "configures MGG correctly during setup" do
      executor.execute

      # MGG should be configured with the executor's parameters
      expect(Genalgo::MGG.n_dim).to eq(3)
      expect(Genalgo::MGG.lower_limit).to eq(-5.0)
      expect(Genalgo::MGG.upper_limit).to eq(5.0)
      expect(Genalgo::MGG.crossover).to eq(:blx_alpha)
    end
  end

  describe "evaluation counting and termination" do
    let(:small_budget_params) { default_params.merge(n_eval: 20, n_pop: 6) }
    subject(:executor) { described_class.new(small_budget_params) }

    it "terminates before exceeding evaluation budget" do
      executor.execute
      total_evaluations = executor.history.last.evaluations
      expect(total_evaluations).to be <= 20
    end

    it "performs at least the initial population evaluation" do
      executor.execute
      expect(executor.history.first.evaluations).to eq(6) # n_pop
    end

    it "tracks evaluations correctly throughout execution" do
      executor.execute
      evaluations = executor.history.map(&:evaluations)

      # Should start with n_pop and increase by 2 each generation
      expect(evaluations.first).to eq(6)
      evaluations.each_cons(2) do |prev, curr|
        expect(curr - prev).to eq(2) # evaluations_per_generation
      end
    end
  end

  describe "population bounds enforcement" do
    let(:tight_bounds_params) do
      default_params.merge(upper_limit: 1.0, lower_limit: -1.0)
    end
    subject(:executor) { described_class.new(tight_bounds_params) }

    it "creates initial population within bounds" do
      executor.execute
      executor.population.each do |individual|
        individual.chromosome.each do |gene|
          expect(gene).to be_between(-1.0, 1.0)
        end
      end
    end

    it "maintains bounds throughout evolution" do
      executor.execute
      executor.population.each do |individual|
        individual.chromosome.each do |gene|
          expect(gene).to be_between(-1.0, 1.0)
        end
      end
    end
  end

  describe "convergence behavior" do
    let(:convergence_params) do
      default_params.merge(
        n_eval: 100,
        evaluation_function: ->(chromosome) { chromosome.map { |x| (x - 1.0)**2 }.sum }
      )
    end
    subject(:executor) { described_class.new(convergence_params) }

    it "shows fitness improvement over generations" do
      executor.execute

      fitness_values = executor.history.map { |data| data.best_individual.fitness }

      # First and last fitness - there should be improvement (lower is better)
      expect(fitness_values.last).to be <= fitness_values.first
    end

    it "maintains history of best individuals" do
      executor.execute

      executor.history.each do |data|
        expect(data.best_individual).to be_a(Genalgo::Individual)
        expect(data.evaluations).to be_a(Integer)
        expect(data.evaluations).to be_positive
      end
    end
  end

  describe "different problem dimensions" do
    [1, 2, 5, 10].each do |dim|
      context "with #{dim} dimensions" do
        let(:dim_params) { default_params.merge(n_dim: dim) }
        subject(:executor) { described_class.new(dim_params) }

        it "handles #{dim}D problems correctly" do
          executor.execute

          executor.population.each do |individual|
            expect(individual.chromosome.size).to eq(dim)
          end
        end
      end
    end
  end
end
