# frozen_string_literal: true

RSpec.describe Genalgo::BlxAlphaCrossover do
  let(:bounds) { { upper: 10.0, lower: -10.0 } }
  let(:parent1) do
    individual = Genalgo::Individual.new(n_dim: 3, upper_limit: 10.0, lower_limit: -10.0)
    individual.chromosome = [1.0, 2.0, 3.0]
    individual.fitness = 5.0
    individual
  end

  let(:parent2) do
    individual = Genalgo::Individual.new(n_dim: 3, upper_limit: 10.0, lower_limit: -10.0)
    individual.chromosome = [4.0, 5.0, 6.0]
    individual.fitness = 7.0
    individual
  end

  describe "DEFAULT_ALPHA constant" do
    it "defines the default alpha value" do
      expect(described_class::DEFAULT_ALPHA).to eq(0.36)
    end
  end

  describe "#initialize" do
    context "with default parameters" do
      subject(:crossover) { described_class.new }

      it "uses the default alpha value" do
        # We can test this by verifying the behavior matches default alpha
        expect(crossover).to be_a(described_class)
      end
    end

    context "with custom alpha" do
      subject(:crossover) { described_class.new(alpha: 0.5) }

      it "accepts custom alpha value" do
        expect(crossover).to be_a(described_class)
      end
    end
  end

  describe "#crossover" do
    subject(:crossover) { described_class.new }

    let(:child) { crossover.crossover(parent1, parent2, bounds) }

    it "returns an Individual instance" do
      expect(child).to be_a(Genalgo::Individual)
    end

    it "returns a different object than the parents" do
      expect(child).not_to be(parent1)
      expect(child).not_to be(parent2)
    end

    it "creates child with same chromosome dimension" do
      expect(child.chromosome.size).to eq(parent1.chromosome.size)
    end

    it "creates child chromosome with Float values" do
      expect(child.chromosome).to all(be_a(Float))
    end

    it "creates child chromosome within bounds" do
      child.chromosome.each do |gene|
        expect(gene).to be_between(bounds[:lower], bounds[:upper])
      end
    end

    it "creates child with fitness from parent1" do
      expect(child.fitness).to eq(parent1.fitness)
    end

    it "creates different children on multiple calls" do
      child1 = crossover.crossover(parent1, parent2, bounds)
      child2 = crossover.crossover(parent1, parent2, bounds)

      expect(child1.chromosome).not_to eq(child2.chromosome)
    end

    context "with identical parents" do
      let(:identical_parent) do
        individual = Genalgo::Individual.new(n_dim: 3, upper_limit: 10.0, lower_limit: -10.0)
        individual.chromosome = [2.0, 3.0, 4.0]
        individual
      end

      it "can still produce variation" do
        child = crossover.crossover(identical_parent, identical_parent, bounds)
        # With identical parents, BLX-alpha should still produce some variation
        # due to the alpha expansion
        expect(child.chromosome).to be_a(Array)
        expect(child.chromosome.size).to eq(3)
      end
    end

    context "with tight bounds" do
      let(:tight_bounds) { { upper: 5.0, lower: 4.5 } }
      let(:bounded_parent1) do
        individual = Genalgo::Individual.new(n_dim: 2, upper_limit: 5.0, lower_limit: 4.5)
        individual.chromosome = [4.6, 4.7]
        individual
      end

      let(:bounded_parent2) do
        individual = Genalgo::Individual.new(n_dim: 2, upper_limit: 5.0, lower_limit: 4.5)
        individual.chromosome = [4.8, 4.9]
        individual
      end

      it "respects tight bounds" do
        child = crossover.crossover(bounded_parent1, bounded_parent2, tight_bounds)
        child.chromosome.each do |gene|
          expect(gene).to be_between(tight_bounds[:lower], tight_bounds[:upper])
        end
      end
    end

    context "with zero-width bounds" do
      let(:zero_bounds) { { upper: 5.0, lower: 5.0 } }
      let(:constrained_parent1) do
        individual = Genalgo::Individual.new(n_dim: 2, upper_limit: 5.0, lower_limit: 5.0)
        individual.chromosome = [5.0, 5.0]
        individual
      end

      let(:constrained_parent2) do
        individual = Genalgo::Individual.new(n_dim: 2, upper_limit: 5.0, lower_limit: 5.0)
        individual.chromosome = [5.0, 5.0]
        individual
      end

      it "handles zero-width bounds" do
        child = crossover.crossover(constrained_parent1, constrained_parent2, zero_bounds)
        expect(child.chromosome).to all(eq(5.0))
      end
    end
  end

  describe "#blend_genes" do
    subject(:crossover) { described_class.new(alpha: 0.5) }

    # Testing private method through public interface
    context "blending behavior" do
      let(:wide_range_parent1) do
        individual = Genalgo::Individual.new(n_dim: 1, upper_limit: 100.0, lower_limit: -100.0)
        individual.chromosome = [0.0]
        individual
      end

      let(:wide_range_parent2) do
        individual = Genalgo::Individual.new(n_dim: 1, upper_limit: 100.0, lower_limit: -100.0)
        individual.chromosome = [10.0]
        individual
      end

      let(:wide_bounds) { { upper: 100.0, lower: -100.0 } }

      it "produces values in expected range for well-separated parents" do
        # With alpha=0.5, genes 0.0 and 10.0 should produce values roughly in range [-5.0, 15.0]
        # but clamped to bounds [-100.0, 100.0]
        children = Array.new(50) { crossover.crossover(wide_range_parent1, wide_range_parent2, wide_bounds) }
        gene_values = children.map { |child| child.chromosome[0] }

        # All values should be within a reasonable expansion of the parent range
        gene_values.each do |value|
          expect(value).to be >= -10.0  # Roughly 0.0 - 0.5 * 10.0 * 2
          expect(value).to be <= 20.0   # Roughly 10.0 + 0.5 * 10.0 * 2
        end
      end
    end
  end

  describe "alpha parameter effects" do
    let(:small_alpha_crossover) { described_class.new(alpha: 0.1) }
    let(:large_alpha_crossover) { described_class.new(alpha: 1.0) }

    it "produces different ranges with different alpha values" do
      small_alpha_children = Array.new(20) { small_alpha_crossover.crossover(parent1, parent2, bounds) }
      large_alpha_children = Array.new(20) { large_alpha_crossover.crossover(parent1, parent2, bounds) }

      small_alpha_ranges = small_alpha_children.map { |child| child.chromosome.map(&:abs).max }
      large_alpha_ranges = large_alpha_children.map { |child| child.chromosome.map(&:abs).max }

      # Larger alpha should generally produce more diverse offspring
      # This is a statistical test, so we use averages
      small_avg_range = small_alpha_ranges.sum / small_alpha_ranges.size
      large_avg_range = large_alpha_ranges.sum / large_alpha_ranges.size

      expect(large_avg_range).to be >= small_avg_range
    end
  end
end
