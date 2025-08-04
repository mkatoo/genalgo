# frozen_string_literal: true

RSpec.describe Genalgo::GenerationManager do
  let(:n_dim) { 3 }
  let(:bounds) { { upper: 10.0, lower: -10.0 } }
  let(:evaluation_function) { lambda(&:sum) }

  let(:blx_alpha_crossover) { Genalgo::BlxAlphaCrossover.new }
  let(:simplex_crossover) { Genalgo::SimplexCrossover.new(n_dim) }
  let(:selection_strategy) { Genalgo::EliteRouletteSelection.new }

  let(:population) do
    pop = Genalgo::Population.new(n_pop: 6, n_dim: n_dim, lower_limit: bounds[:lower], upper_limit: bounds[:upper])
    # Set known fitness values for predictable testing
    pop.each_with_index do |individual, i|
      individual.fitness = (i + 1) * 2.0
    end
    pop
  end

  describe "#initialize" do
    subject(:manager) do
      described_class.new(blx_alpha_crossover, selection_strategy, evaluation_function, n_dim, bounds)
    end

    it "creates a generation manager instance" do
      expect(manager).to be_a(described_class)
    end

    it "accepts all required parameters" do
      expect(manager).to be_a(described_class)
    end
  end

  describe "#evaluations_per_generation" do
    subject(:manager) do
      described_class.new(blx_alpha_crossover, selection_strategy, evaluation_function, n_dim, bounds)
    end

    it "returns 2 evaluations per generation" do
      expect(manager.evaluations_per_generation).to eq(2)
    end
  end

  describe "#next_generation" do
    context "with BLX-alpha crossover" do
      subject(:manager) do
        described_class.new(blx_alpha_crossover, selection_strategy, evaluation_function, n_dim, bounds)
      end

      let(:result_population) { manager.next_generation(population) }

      it "returns a population of the same size" do
        expect(result_population.size).to eq(population.size)
      end

      it "returns a Population instance" do
        expect(result_population).to be_a(Genalgo::Population)
      end

      it "evaluates children with the evaluation function" do
        # All individuals should have fitness values (not nil)
        result_population.each do |individual|
          expect(individual.fitness).not_to be_nil
          expect(individual.fitness).to be_a(Numeric)
        end
      end

      it "does not modify the original population" do
        original_size = population.size
        manager.next_generation(population)
        expect(population.size).to eq(original_size)
      end

      # Removed randomness test as requested - randomness tests are not needed
    end

    context "with Simplex crossover" do
      subject(:manager) do
        described_class.new(simplex_crossover, selection_strategy, evaluation_function, n_dim, bounds)
      end

      let(:result_population) { manager.next_generation(population) }

      it "returns a population of the same size" do
        expect(result_population.size).to eq(population.size)
      end

      it "returns a Population instance" do
        expect(result_population).to be_a(Genalgo::Population)
      end

      it "evaluates children with the evaluation function" do
        result_population.each do |individual|
          expect(individual.fitness).not_to be_nil
          expect(individual.fitness).to be_a(Numeric)
        end
      end

      # Removed randomness test as requested - randomness tests are not needed
    end

    context "with unknown crossover strategy" do
      let(:unknown_crossover) { double("UnknownCrossover") }
      subject(:manager) do
        described_class.new(unknown_crossover, selection_strategy, evaluation_function, n_dim, bounds)
      end

      it "raises ArgumentError for unknown crossover strategy" do
        expect { manager.next_generation(population) }.to raise_error(
          ArgumentError, /Unknown crossover strategy/
        )
      end
    end
  end

  describe "BLX-alpha generation handling" do
    subject(:manager) do
      described_class.new(blx_alpha_crossover, selection_strategy, evaluation_function, n_dim, bounds)
    end

    let(:small_population) do
      pop = Genalgo::Population.new(n_pop: 4, n_dim: n_dim, lower_limit: bounds[:lower], upper_limit: bounds[:upper])
      pop.each_with_index { |individual, i| individual.fitness = i + 1.0 }
      pop
    end

    it "removes 2 parents and adds selected individuals back" do
      result = manager.next_generation(small_population)
      expect(result.size).to eq(4)
    end

    it "maintains population diversity" do
      original_chromosomes = small_population.map(&:chromosome)
      result = manager.next_generation(small_population)
      result_chromosomes = result.map(&:chromosome)

      # Some chromosomes should be different due to crossover
      expect(result_chromosomes).not_to eq(original_chromosomes)
    end
  end

  describe "Simplex generation handling" do
    subject(:manager) do
      described_class.new(simplex_crossover, selection_strategy, evaluation_function, n_dim, bounds)
    end

    it "handles n_dim + 1 parents correctly" do
      # Simplex needs n_dim + 1 parents (4 for 3D problem)
      result = manager.next_generation(population)
      expect(result.size).to eq(population.size)
    end

    it "maintains population consistency" do
      result = manager.next_generation(population)

      result.each do |individual|
        expect(individual).to be_a(Genalgo::Individual)
        expect(individual.chromosome.size).to eq(n_dim)
        expect(individual.fitness).to be_a(Numeric)
      end
    end
  end

  describe "evaluation function integration" do
    let(:square_sum_function) { ->(chromosome) { chromosome.map { |x| x * x }.sum } }

    subject(:manager) do
      described_class.new(blx_alpha_crossover, selection_strategy, square_sum_function, n_dim, bounds)
    end

    context "with different evaluation functions" do
      let(:absolute_sum_function) { ->(chromosome) { chromosome.map(&:abs).sum } }
      let(:abs_manager) do
        described_class.new(blx_alpha_crossover, selection_strategy, absolute_sum_function, n_dim, bounds)
      end

      it "produces different fitness values with different functions" do
        result1 = manager.next_generation(population)
        pop_copy = population.dup
        result2 = abs_manager.next_generation(pop_copy)

        # Different evaluation functions should produce different fitness patterns
        fitness1 = result1.map(&:fitness).sort
        fitness2 = result2.map(&:fitness).sort
        expect(fitness1).not_to eq(fitness2)
      end
    end
  end

  describe "selection strategy integration" do
    let(:different_selection) { Genalgo::EliteRouletteSelection.new(scaling_factor: 0.1) }

    subject(:manager_with_different_selection) do
      described_class.new(blx_alpha_crossover, different_selection, evaluation_function, n_dim, bounds)
    end

    it "uses the provided selection strategy" do
      result = manager_with_different_selection.next_generation(population)
      expect(result.size).to eq(population.size)
      expect(result).to all(be_a(Genalgo::Individual))
    end
  end

  describe "bounds handling" do
    let(:tight_bounds) { { upper: 1.0, lower: -1.0 } }
    let(:tight_population) do
      pop = Genalgo::Population.new(n_pop: 4, n_dim: n_dim, lower_limit: tight_bounds[:lower],
                                    upper_limit: tight_bounds[:upper])
      pop.each { |individual| individual.fitness = rand * 10 }
      pop
    end

    subject(:manager_with_tight_bounds) do
      described_class.new(blx_alpha_crossover, selection_strategy, evaluation_function, n_dim, tight_bounds)
    end

    it "respects the provided bounds during crossover" do
      result = manager_with_tight_bounds.next_generation(tight_population)

      result.each do |individual|
        individual.chromosome.each do |gene|
          expect(gene).to be_between(tight_bounds[:lower], tight_bounds[:upper])
        end
      end
    end
  end

  describe "population duplication behavior" do
    subject(:manager) do
      described_class.new(blx_alpha_crossover, selection_strategy, evaluation_function, n_dim, bounds)
    end

    it "does not modify the input population" do
      original_individuals = population.to_a.dup
      manager.next_generation(population)

      # Original population should be unchanged
      expect(population.to_a).to eq(original_individuals)
    end
  end
end
