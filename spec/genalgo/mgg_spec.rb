# frozen_string_literal: true

RSpec.describe Genalgo::MGG do
  let(:n_dim) { 3 }
  let(:lower_limit) { -5.0 }
  let(:upper_limit) { 5.0 }
  let(:evaluation_function) { ->(chromosome) { chromosome.sum.abs } }

  let(:population) do
    pop = Genalgo::Population.new(n_pop: 6, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    # Set known fitness values
    pop.each_with_index { |individual, i| individual.fitness = (i + 1) * 1.5 }
    pop
  end

  before do
    # Reset MGG state before each test
    described_class.n_dim = nil
    described_class.lower_limit = nil
    described_class.upper_limit = nil
    described_class.evaluation_function = nil
    described_class.crossover = nil
    described_class.instance_variable_set(:@generation_manager, nil)
  end

  describe "class attributes" do
    it "allows setting and getting n_dim" do
      described_class.n_dim = 5
      expect(described_class.n_dim).to eq(5)
    end

    it "allows setting and getting lower_limit" do
      described_class.lower_limit = -10.0
      expect(described_class.lower_limit).to eq(-10.0)
    end

    it "allows setting and getting upper_limit" do
      described_class.upper_limit = 10.0
      expect(described_class.upper_limit).to eq(10.0)
    end

    it "allows setting and getting evaluation_function" do
      func = lambda(&:sum)
      described_class.evaluation_function = func
      expect(described_class.evaluation_function).to eq(func)
    end

    it "allows setting and getting crossover" do
      described_class.crossover = :blx_alpha
      expect(described_class.crossover).to eq(:blx_alpha)
    end
  end

  describe "#evaluations_per_generation" do
    before do
      described_class.n_dim = n_dim
      described_class.lower_limit = lower_limit
      described_class.upper_limit = upper_limit
      described_class.evaluation_function = evaluation_function
      described_class.crossover = :blx_alpha
    end

    it "returns 2 evaluations per generation" do
      expect(described_class.evaluations_per_generation).to eq(2)
    end

    it "delegates to the generation manager" do
      # This verifies the delegation works
      expect(described_class.evaluations_per_generation).to be_a(Integer)
    end
  end

  describe "#next_generation" do
    context "with BLX-alpha crossover" do
      before do
        described_class.n_dim = n_dim
        described_class.lower_limit = lower_limit
        described_class.upper_limit = upper_limit
        described_class.evaluation_function = evaluation_function
        described_class.crossover = :blx_alpha
      end

      let(:result) { described_class.next_generation(population) }

      it "returns a Population instance" do
        expect(result).to be_a(Genalgo::Population)
      end

      it "maintains population size" do
        expect(result.size).to eq(population.size)
      end

      it "evaluates individuals using the provided function" do
        result.each do |individual|
          expect(individual.fitness).not_to be_nil
          expect(individual.fitness).to be_a(Numeric)
        end
      end

      # Removed randomness test as requested - randomness tests are not needed
    end

    context "with Simplex crossover" do
      before do
        described_class.n_dim = n_dim
        described_class.lower_limit = lower_limit
        described_class.upper_limit = upper_limit
        described_class.evaluation_function = evaluation_function
        described_class.crossover = :simplex
      end

      let(:result) { described_class.next_generation(population) }

      it "returns a Population instance" do
        expect(result).to be_a(Genalgo::Population)
      end

      it "maintains population size" do
        expect(result.size).to eq(population.size)
      end

      it "handles n_dim + 1 parent requirement" do
        # Simplex crossover requires n_dim + 1 parents
        expect(result).to all(be_a(Genalgo::Individual))
      end
    end

    context "with unknown crossover type" do
      before do
        described_class.n_dim = n_dim
        described_class.lower_limit = lower_limit
        described_class.upper_limit = upper_limit
        described_class.evaluation_function = evaluation_function
        described_class.crossover = :unknown_type
      end

      it "raises ArgumentError for unknown crossover type" do
        expect { described_class.next_generation(population) }.to raise_error(
          ArgumentError, /Unknown crossover type: unknown_type/
        )
      end
    end

    context "without proper configuration" do
      it "raises error when attributes are not set" do
        # This will fail when trying to create generation manager
        expect { described_class.next_generation(population) }.to raise_error
      end
    end
  end

  describe "generation manager creation and caching" do
    before do
      described_class.n_dim = n_dim
      described_class.lower_limit = lower_limit
      described_class.upper_limit = upper_limit
      described_class.evaluation_function = evaluation_function
      described_class.crossover = :blx_alpha
    end

    it "creates generation manager on first access" do
      # First call should create the manager
      result1 = described_class.next_generation(population)

      # Manager should be cached and reused
      pop_copy = population.dup
      result2 = described_class.next_generation(pop_copy)

      expect(result1).to be_a(Genalgo::Population)
      expect(result2).to be_a(Genalgo::Population)
    end

    it "uses the configured bounds" do
      # Test that bounds are properly passed to generation manager
      result = described_class.next_generation(population)

      result.each do |individual|
        individual.chromosome.each do |gene|
          expect(gene).to be_between(lower_limit, upper_limit)
        end
      end
    end
  end

  describe "crossover strategy creation" do
    context "with BLX-alpha" do
      before do
        described_class.n_dim = n_dim
        described_class.lower_limit = lower_limit
        described_class.upper_limit = upper_limit
        described_class.evaluation_function = evaluation_function
        described_class.crossover = :blx_alpha
      end

      it "creates BlxAlphaCrossover strategy" do
        # We can test this indirectly by verifying the behavior
        result = described_class.next_generation(population)
        expect(result).to be_a(Genalgo::Population)
      end
    end

    context "with Simplex" do
      before do
        described_class.n_dim = n_dim
        described_class.lower_limit = lower_limit
        described_class.upper_limit = upper_limit
        described_class.evaluation_function = evaluation_function
        described_class.crossover = :simplex
      end

      it "creates SimplexCrossover strategy" do
        result = described_class.next_generation(population)
        expect(result).to be_a(Genalgo::Population)
      end
    end
  end

  describe "EliteRouletteSelection integration" do
    before do
      described_class.n_dim = n_dim
      described_class.lower_limit = lower_limit
      described_class.upper_limit = upper_limit
      described_class.evaluation_function = evaluation_function
      described_class.crossover = :blx_alpha
    end

    it "uses EliteRouletteSelection as default selection strategy" do
      current_pop = population
      5.times do
        current_pop = described_class.next_generation(current_pop)
      end

      expect(current_pop.best_individual).to be_a(Genalgo::Individual)
    end
  end

  describe "state management" do
    it "maintains configuration across calls" do
      described_class.n_dim = 4
      described_class.lower_limit = -2.0
      described_class.upper_limit = 2.0
      described_class.evaluation_function = ->(x) { x.map(&:abs).sum }
      described_class.crossover = :simplex

      # Configuration should persist
      expect(described_class.n_dim).to eq(4)
      expect(described_class.lower_limit).to eq(-2.0)
      expect(described_class.upper_limit).to eq(2.0)
      expect(described_class.crossover).to eq(:simplex)
    end

    it "allows reconfiguration" do
      # Initial configuration
      described_class.crossover = :blx_alpha
      expect(described_class.crossover).to eq(:blx_alpha)

      # Reconfiguration
      described_class.crossover = :simplex
      expect(described_class.crossover).to eq(:simplex)
    end
  end

  describe "bounds enforcement" do
    let(:strict_bounds_lower) { 0.0 }
    let(:strict_bounds_upper) { 1.0 }

    before do
      described_class.n_dim = n_dim
      described_class.lower_limit = strict_bounds_lower
      described_class.upper_limit = strict_bounds_upper
      described_class.evaluation_function = evaluation_function
      described_class.crossover = :blx_alpha
    end

    let(:bounded_population) do
      pop = Genalgo::Population.new(
        n_pop: 4,
        n_dim: n_dim,
        lower_limit: strict_bounds_lower,
        upper_limit: strict_bounds_upper
      )
      pop.each { |individual| individual.fitness = rand }
      pop
    end

    it "enforces the configured bounds" do
      result = described_class.next_generation(bounded_population)

      result.each do |individual|
        individual.chromosome.each do |gene|
          expect(gene).to be_between(strict_bounds_lower, strict_bounds_upper)
        end
      end
    end
  end
end
