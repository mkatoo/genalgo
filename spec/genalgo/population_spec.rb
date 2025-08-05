# frozen_string_literal: true

RSpec.describe Genalgo::Population do
  let(:n_pop) { 10 }
  let(:n_dim) { 5 }
  let(:lower_limit) { -10.0 }
  let(:upper_limit) { 10.0 }

  describe "#initialize" do
    context "with valid parameters" do
      subject(:population) do
        described_class.new(n_pop: n_pop, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
      end

      it "creates the correct number of individuals" do
        expect(population.size).to eq(n_pop)
      end

      it "creates individuals with correct dimensions" do
        population.each do |individual|
          expect(individual.chromosome.size).to eq(n_dim)
        end
      end

      it "creates individuals within bounds" do
        population.each do |individual|
          individual.chromosome.each do |gene|
            expect(gene).to be_between(lower_limit, upper_limit)
          end
        end
      end

      it "creates Individual instances" do
        expect(population).to all(be_a(Genalgo::Individual))
      end
    end

    context "with invalid parameters" do
      it "raises error for zero population size" do
        expect do
          described_class.new(n_pop: 0, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
        end.to raise_error(ArgumentError, "Population size (n_pop) must be at least 1, got 0")
      end

      it "raises error for negative population size" do
        expect do
          described_class.new(n_pop: -1, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
        end.to raise_error(ArgumentError, "Population size (n_pop) must be at least 1, got -1")
      end

      it "raises error for zero dimensions" do
        expect do
          described_class.new(n_pop: n_pop, n_dim: 0, lower_limit: lower_limit, upper_limit: upper_limit)
        end.to raise_error(ArgumentError, "Dimension (n_dim) must be at least 1, got 0")
      end

      it "raises error for negative dimensions" do
        expect do
          described_class.new(n_pop: n_pop, n_dim: -1, lower_limit: lower_limit, upper_limit: upper_limit)
        end.to raise_error(ArgumentError, "Dimension (n_dim) must be at least 1, got -1")
      end
    end
  end

  describe "Enumerable interface" do
    subject(:population) do
      described_class.new(n_pop: n_pop, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    end

    it "includes Enumerable module" do
      expect(described_class.ancestors).to include(Enumerable)
    end

    it "responds to each" do
      expect(population).to respond_to(:each)
    end

    it "supports map operation" do
      chromosome_sizes = population.map { |individual| individual.chromosome.size }
      expect(chromosome_sizes).to all(eq(n_dim))
    end

    it "supports select operation" do
      # Set some fitness values
      population.each_with_index { |individual, index| individual.fitness = index }
      selected = population.select { |individual| individual.fitness < 5 }
      expect(selected.size).to eq(5)
    end

    it "supports size method" do
      expect(population.size).to eq(n_pop)
    end
  end

  describe "#add" do
    subject(:population) do
      described_class.new(n_pop: 5, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    end

    let(:new_individuals) do
      [
        Genalgo::Individual.new(n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit),
        Genalgo::Individual.new(n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
      ]
    end

    it "adds individuals to the population" do
      original_size = population.size
      population.add(new_individuals)
      expect(population.size).to eq(original_size + 2)
    end

    it "adds the correct individuals" do
      population.add(new_individuals)
      expect(population.to_a).to include(*new_individuals)
    end

    it "handles empty array" do
      original_size = population.size
      population.add([])
      expect(population.size).to eq(original_size)
    end
  end

  describe "#sample" do
    subject(:population) do
      described_class.new(n_pop: n_pop, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    end

    it "returns the requested number of individuals" do
      sampled = population.sample(3)
      expect(sampled.size).to eq(3)
    end

    it "returns Individual instances" do
      sampled = population.sample(2)
      expect(sampled).to all(be_a(Genalgo::Individual))
    end

    it "returns individuals from the population" do
      sampled = population.sample(5)
      sampled.each do |individual|
        expect(population.to_a).to include(individual)
      end
    end

    it "does not modify the original population" do
      original_size = population.size
      population.sample(3)
      expect(population.size).to eq(original_size)
    end

    it "handles sampling entire population" do
      sampled = population.sample(n_pop)
      expect(sampled.size).to eq(n_pop)
    end
  end

  describe "#delete" do
    subject(:population) do
      described_class.new(n_pop: n_pop, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    end

    let(:individuals_to_delete) { population.sample(3) }

    it "removes individuals from population" do
      original_size = population.size
      population.delete(individuals_to_delete)
      expect(population.size).to eq(original_size - 3)
    end

    it "returns the deleted individuals" do
      deleted = population.delete(individuals_to_delete)
      expect(deleted).to eq(individuals_to_delete)
    end

    it "actually removes the individuals" do
      population.delete(individuals_to_delete)
      individuals_to_delete.each do |individual|
        expect(population.to_a).not_to include(individual)
      end
    end

    it "handles empty array" do
      original_size = population.size
      result = population.delete([])
      expect(population.size).to eq(original_size)
      expect(result).to eq([])
    end
  end

  describe "#pop" do
    subject(:population) do
      described_class.new(n_pop: n_pop, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    end

    it "removes and returns the requested number of individuals" do
      original_size = population.size
      popped = population.pop(3)

      expect(popped.size).to eq(3)
      expect(population.size).to eq(original_size - 3)
    end

    it "returns Individual instances" do
      popped = population.pop(2)
      expect(popped).to all(be_a(Genalgo::Individual))
    end

    it "removes the returned individuals from population" do
      popped = population.pop(3)
      popped.each do |individual|
        expect(population.to_a).not_to include(individual)
      end
    end
  end

  describe "#best_individual" do
    subject(:population) do
      described_class.new(n_pop: 5, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    end

    before do
      # Set fitness values: 10.0, 5.0, 15.0, 2.0, 8.0
      population.each_with_index do |individual, index|
        individual.fitness = [10.0, 5.0, 15.0, 2.0, 8.0][index]
      end
    end

    it "returns the individual with minimum fitness" do
      best = population.best_individual
      expect(best.fitness).to eq(2.0)
    end

    it "returns an Individual instance" do
      expect(population.best_individual).to be_a(Genalgo::Individual)
    end

    context "with no fitness values set" do
      subject(:population_no_fitness) do
        described_class.new(n_pop: 3, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
      end

      it "handles nil fitness values" do
        # When all fitness values are nil, min_by should return the first individual
        expect(population_no_fitness.best_individual).to be_a(Genalgo::Individual)
      end
    end

    context "with negative fitness values" do
      before do
        population.each_with_index do |individual, index|
          individual.fitness = [-5.0, -10.0, -2.0, -15.0, -8.0][index]
        end
      end

      it "correctly identifies minimum among negative values" do
        best = population.best_individual
        expect(best.fitness).to eq(-15.0)
      end
    end
  end

  describe "population consistency" do
    subject(:population) do
      described_class.new(n_pop: n_pop, n_dim: n_dim, lower_limit: lower_limit, upper_limit: upper_limit)
    end

    it "maintains all individuals as unique objects" do
      individuals = population.to_a
      individuals.each_with_index do |individual, i|
        individuals[(i + 1)..].each do |other_individual|
          expect(individual).not_to be(other_individual)
        end
      end
    end

    it "maintains population integrity after operations" do
      original_individuals = population.to_a.dup

      # Sample some individuals (sampling doesn't modify population)
      population.sample(3)

      # Population should still contain all original individuals
      expect(population.size).to eq(n_pop)
      original_individuals.each do |individual|
        expect(population.to_a).to include(individual)
      end
    end
  end
end
