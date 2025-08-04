# frozen_string_literal: true

RSpec.describe Genalgo::Individual do
  let(:n_dim) { 5 }
  let(:upper_limit) { 10.0 }
  let(:lower_limit) { -5.0 }

  describe "#initialize" do
    context "with default parameters" do
      subject(:individual) do
        described_class.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)
      end

      it "sets the correct dimension" do
        expect(individual.chromosome.size).to eq(n_dim)
      end

      it "initializes chromosome within bounds" do
        individual.chromosome.each do |gene|
          expect(gene).to be_between(lower_limit, upper_limit)
        end
      end

      it "has nil fitness initially" do
        expect(individual.fitness).to be_nil
      end

      it "creates an array of floats for chromosome" do
        expect(individual.chromosome).to all(be_a(Float))
      end
    end

    context "with custom chromosome" do
      let(:custom_chromosome) { [1.0, 2.0, 3.0, 4.0, 5.0] }
      subject(:individual) do
        described_class.new(
          n_dim: n_dim,
          upper_limit: upper_limit,
          lower_limit: lower_limit,
          chromosome: custom_chromosome
        )
      end

      it "uses the provided chromosome" do
        expect(individual.chromosome).to eq(custom_chromosome)
      end

      it "does not overwrite the custom chromosome" do
        expect(individual.chromosome).to be(custom_chromosome)
      end
    end

    context "with edge case bounds" do
      let(:zero_range_upper) { 5.0 }
      let(:zero_range_lower) { 5.0 }

      subject(:individual) do
        described_class.new(
          n_dim: 3,
          upper_limit: zero_range_upper,
          lower_limit: zero_range_lower
        )
      end

      it "handles zero range (upper == lower)" do
        expect(individual.chromosome).to all(eq(5.0))
      end
    end
  end

  describe "#fitness=" do
    subject(:individual) do
      described_class.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)
    end

    it "allows setting fitness value" do
      individual.fitness = 42.5
      expect(individual.fitness).to eq(42.5)
    end

    it "allows setting negative fitness" do
      individual.fitness = -10.0
      expect(individual.fitness).to eq(-10.0)
    end

    it "allows setting zero fitness" do
      individual.fitness = 0.0
      expect(individual.fitness).to eq(0.0)
    end
  end

  describe "#chromosome=" do
    subject(:individual) do
      described_class.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)
    end

    it "allows setting a new chromosome" do
      new_chromosome = [9.0, 8.0, 7.0, 6.0, 5.0]
      individual.chromosome = new_chromosome
      expect(individual.chromosome).to eq(new_chromosome)
    end
  end

  describe "#initialize_chromosome" do
    subject(:individual) do
      described_class.new(
        n_dim: n_dim,
        upper_limit: upper_limit,
        lower_limit: lower_limit,
        chromosome: [1.0, 2.0, 3.0, 4.0, 5.0]
      )
    end

    it "regenerates the chromosome within bounds" do
      original_chromosome = individual.chromosome.dup
      individual.initialize_chromosome

      expect(individual.chromosome).not_to eq(original_chromosome)
      individual.chromosome.each do |gene|
        expect(gene).to be_between(lower_limit, upper_limit)
      end
    end

    it "maintains the correct chromosome size" do
      individual.initialize_chromosome
      expect(individual.chromosome.size).to eq(n_dim)
    end
  end

  describe "randomness and reproducibility" do
    it "produces different chromosomes on different initializations" do
      individual1 = described_class.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)
      individual2 = described_class.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)

      expect(individual1.chromosome).not_to eq(individual2.chromosome)
    end

    context "with seeded random" do
      before { srand(12_345) }
      after { srand }

      it "produces reproducible results with same seed" do
        srand(12_345)
        individual1 = described_class.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)

        srand(12_345)
        individual2 = described_class.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)

        expect(individual1.chromosome).to eq(individual2.chromosome)
      end
    end
  end
end
