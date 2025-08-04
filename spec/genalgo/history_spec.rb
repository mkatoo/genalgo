# frozen_string_literal: true

RSpec.describe Genalgo::History do
  let(:individual1) do
    individual = Genalgo::Individual.new(n_dim: 3, upper_limit: 10.0, lower_limit: -10.0)
    individual.fitness = 5.0
    individual
  end

  let(:individual2) do
    individual = Genalgo::Individual.new(n_dim: 3, upper_limit: 10.0, lower_limit: -10.0)
    individual.fitness = 3.0
    individual
  end

  let(:individual3) do
    individual = Genalgo::Individual.new(n_dim: 3, upper_limit: 10.0, lower_limit: -10.0)
    individual.fitness = 1.0
    individual
  end

  describe "#initialize" do
    subject(:history) { described_class.new }

    it "creates an empty history" do
      expect(history.to_a).to be_empty
    end

    it "includes Enumerable module" do
      expect(described_class.ancestors).to include(Enumerable)
    end
  end

  describe "#add" do
    subject(:history) { described_class.new }

    it "adds a history data point" do
      history.add(individual1, 100)
      expect(history.to_a.size).to eq(1)
    end

    it "creates a Data instance" do
      history.add(individual1, 100)
      expect(history.first).to be_a(Genalgo::History::Data)
    end

    it "stores the evaluation count" do
      history.add(individual1, 150)
      expect(history.first.evaluations).to eq(150)
    end

    it "stores a copy of the best individual" do
      history.add(individual1, 100)
      stored_individual = history.first.best_individual

      expect(stored_individual).not_to be(individual1)
      expect(stored_individual.fitness).to eq(individual1.fitness)
      expect(stored_individual.chromosome).to eq(individual1.chromosome)
    end

    it "allows multiple additions" do
      history.add(individual1, 100)
      history.add(individual2, 200)
      history.add(individual3, 300)

      expect(history.to_a.size).to eq(3)
    end

    it "maintains chronological order" do
      history.add(individual1, 100)
      history.add(individual2, 200)
      history.add(individual3, 300)

      evaluations = history.map(&:evaluations)
      expect(evaluations).to eq([100, 200, 300])
    end
  end

  describe "Enumerable interface" do
    subject(:history) { described_class.new }

    before do
      history.add(individual1, 100)
      history.add(individual2, 200)
      history.add(individual3, 300)
    end

    it "supports each iteration" do
      count = 0
      history.each { |_data| count += 1 }
      expect(count).to eq(3)
    end

    it "supports map operation" do
      fitness_values = history.map { |data| data.best_individual.fitness }
      expect(fitness_values).to eq([5.0, 3.0, 1.0])
    end

    it "supports select operation" do
      early_history = history.select { |data| data.evaluations <= 200 }
      expect(early_history.size).to eq(2)
    end

    it "supports size method" do
      expect(history.size).to eq(3)
    end
  end

  describe "delegated methods" do
    subject(:history) { described_class.new }

    context "with empty history" do
      it "returns nil for first" do
        expect(history.first).to be_nil
      end

      it "returns nil for last" do
        expect(history.last).to be_nil
      end
    end

    context "with data" do
      before do
        history.add(individual1, 100)
        history.add(individual2, 200)
        history.add(individual3, 300)
      end

      it "returns first data point" do
        first_data = history.first
        expect(first_data.evaluations).to eq(100)
        expect(first_data.best_individual.fitness).to eq(5.0)
      end

      it "returns last data point" do
        last_data = history.last
        expect(last_data.evaluations).to eq(300)
        expect(last_data.best_individual.fitness).to eq(1.0)
      end
    end
  end

  describe Genalgo::History::Data do
    let(:data) { described_class.new(individual1, 250) }

    describe "#initialize" do
      it "stores the evaluation count" do
        expect(data.evaluations).to eq(250)
      end

      it "stores a copy of the individual" do
        expect(data.best_individual).not_to be(individual1)
        expect(data.best_individual.fitness).to eq(individual1.fitness)
        expect(data.best_individual.chromosome).to eq(individual1.chromosome)
      end

      it "creates an Individual instance" do
        expect(data.best_individual).to be_a(Genalgo::Individual)
      end
    end

    describe "attribute readers" do
      it "provides read access to best_individual" do
        expect(data).to respond_to(:best_individual)
        expect(data.best_individual).to be_a(Genalgo::Individual)
      end

      it "provides read access to evaluations" do
        expect(data).to respond_to(:evaluations)
        expect(data.evaluations).to be_a(Integer)
      end

      it "does not provide write access" do
        expect(data).not_to respond_to(:best_individual=)
        expect(data).not_to respond_to(:evaluations=)
      end
    end
  end

  describe "deep copying behavior" do
    subject(:history) { described_class.new }

    it "prevents mutation of stored individuals" do
      history.add(individual1, 100)
      stored_individual = history.first.best_individual

      # Modify the original individual
      individual1.fitness = 999.0
      individual1.chromosome[0] = 999.0

      # Stored individual should be unchanged
      expect(stored_individual.fitness).to eq(5.0)
      expect(stored_individual.chromosome[0]).not_to eq(999.0)
    end

    it "creates independent copies" do
      history.add(individual1, 100)
      history.add(individual1, 200)

      first_copy = history.first.best_individual
      second_copy = history.last.best_individual

      expect(first_copy).not_to be(second_copy)
      expect(first_copy.fitness).to eq(second_copy.fitness)
    end
  end

  describe "convergence tracking" do
    subject(:history) { described_class.new }

    it "can track fitness improvement over time" do
      # Simulate improving fitness
      individual1.fitness = 10.0
      individual2.fitness = 5.0
      individual3.fitness = 2.0

      history.add(individual1, 100)
      history.add(individual2, 200)
      history.add(individual3, 300)

      fitness_progression = history.map { |data| data.best_individual.fitness }
      expect(fitness_progression).to eq([10.0, 5.0, 2.0])
    end

    it "can track evaluation efficiency" do
      history.add(individual1, 50)
      history.add(individual2, 150)
      history.add(individual3, 300)

      eval_counts = history.map(&:evaluations)
      differences = eval_counts.each_cons(2).map { |a, b| b - a }
      expect(differences).to eq([100, 150])
    end
  end
end
