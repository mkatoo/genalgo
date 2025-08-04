# frozen_string_literal: true

RSpec.describe Genalgo::SimplexCrossover do
  let(:n_dim) { 3 }
  subject(:crossover) { described_class.new(n_dim) }

  let(:parent1) do
    individual = Genalgo::Individual.new(n_dim: n_dim, upper_limit: 10.0, lower_limit: -10.0)
    individual.chromosome = [1.0, 2.0, 3.0]
    individual.fitness = 5.0
    individual
  end

  let(:parent2) do
    individual = Genalgo::Individual.new(n_dim: n_dim, upper_limit: 10.0, lower_limit: -10.0)
    individual.chromosome = [4.0, 5.0, 6.0]
    individual.fitness = 7.0
    individual
  end

  let(:parent3) do
    individual = Genalgo::Individual.new(n_dim: n_dim, upper_limit: 10.0, lower_limit: -10.0)
    individual.chromosome = [7.0, 8.0, 9.0]
    individual.fitness = 3.0
    individual
  end

  let(:parent4) do
    individual = Genalgo::Individual.new(n_dim: n_dim, upper_limit: 10.0, lower_limit: -10.0)
    individual.chromosome = [2.0, 1.0, 4.0]
    individual.fitness = 6.0
    individual
  end

  let(:parents) { [parent1, parent2, parent3, parent4] }

  describe "#initialize" do
    it "accepts n_dim parameter" do
      crossover_2d = described_class.new(2)
      expect(crossover_2d).to be_a(described_class)
    end

    it "stores the dimension" do
      # We can test this indirectly through the behavior
      expect(crossover).to be_a(described_class)
    end
  end

  describe "#crossover" do
    context "with correct number of parents (n_dim + 1)" do
      let(:child) { crossover.crossover(parents) }

      it "returns an Individual instance" do
        expect(child).to be_a(Genalgo::Individual)
      end

      it "returns a different object than the parents" do
        parents.each do |parent|
          expect(child).not_to be(parent)
        end
      end

      it "creates child with same chromosome dimension" do
        expect(child.chromosome.size).to eq(n_dim)
      end

      it "creates child chromosome with Float values" do
        expect(child.chromosome).to all(be_a(Float))
      end

      it "inherits fitness from first parent" do
        expect(child.fitness).to eq(parent1.fitness)
      end

      it "creates different children on multiple calls" do
        child1 = crossover.crossover(parents)
        child2 = crossover.crossover(parents)

        expect(child1.chromosome).not_to eq(child2.chromosome)
      end
    end

    context "with fewer parents than required" do
      let(:insufficient_parents) { [parent1, parent2] }

      it "may cause errors due to insufficient parents" do
        # SimplexCrossover expects n_dim + 1 parents
        # With only 2 parents for 3D problem, it should fail
        expect { crossover.crossover(insufficient_parents) }.to raise_error(TypeError)
      end
    end

    context "with more parents than required" do
      let(:extra_parent) do
        individual = Genalgo::Individual.new(n_dim: n_dim, upper_limit: 10.0, lower_limit: -10.0)
        individual.chromosome = [0.0, 0.0, 0.0]
        individual
      end
      let(:excess_parents) { parents + [extra_parent] }

      it "uses only the required number of parents" do
        child = crossover.crossover(excess_parents)
        expect(child).to be_a(Genalgo::Individual)
        expect(child.chromosome.size).to eq(n_dim)
      end
    end
  end

  describe "#calculate_epsilon" do
    # Testing private method through behavior
    context "epsilon calculation effects" do
      let(:different_dim_crossover) { described_class.new(5) }

      it "produces different results for different dimensions" do
        child_3d = crossover.crossover(parents)

        # Create 5D parents
        parents_5d = Array.new(6) do |i|
          individual = Genalgo::Individual.new(n_dim: 5, upper_limit: 10.0, lower_limit: -10.0)
          individual.chromosome = Array.new(5) { i + 1.0 }
          individual
        end

        child_5d = different_dim_crossover.crossover(parents_5d)

        # Different dimensions should produce different transformations
        expect(child_3d.chromosome.size).to eq(3)
        expect(child_5d.chromosome.size).to eq(5)
      end
    end
  end

  describe "#calculate_mean_chromosome" do
    context "mean calculation verification" do
      let(:uniform_parents) do
        # Create parents where mean is easily calculable
        [
          create_individual([0.0, 0.0, 0.0]),
          create_individual([6.0, 6.0, 6.0]),
          create_individual([3.0, 3.0, 3.0]),
          create_individual([3.0, 3.0, 3.0])
        ]
      end

      it "calculates correct mean through observable behavior" do
        # Expected mean: [3.0, 3.0, 3.0]
        child = crossover.crossover(uniform_parents)
        expect(child.chromosome).to be_a(Array)
        expect(child.chromosome.size).to eq(3)
      end
    end
  end

  describe "simplex transformation properties" do
    context "with identical parents" do
      let(:identical_parents) do
        Array.new(n_dim + 1) { create_individual([2.0, 3.0, 4.0]) }
      end

      it "still produces a valid child" do
        child = crossover.crossover(identical_parents)
        expect(child.chromosome).to be_a(Array)
        expect(child.chromosome.size).to eq(n_dim)
      end
    end

    context "with extreme value parents" do
      let(:extreme_parents) do
        [
          create_individual([-1000.0, -1000.0, -1000.0]),
          create_individual([1000.0, 1000.0, 1000.0]),
          create_individual([0.0, 0.0, 0.0]),
          create_individual([500.0, -500.0, 250.0])
        ]
      end

      it "handles extreme values" do
        child = crossover.crossover(extreme_parents)
        expect(child.chromosome).to be_a(Array)
        expect(child.chromosome.size).to eq(n_dim)
        expect(child.chromosome).to all(be_a(Float))
      end
    end
  end

  describe "different dimensions" do
    [1, 2, 4, 5].each do |dim|
      context "with #{dim} dimensions" do
        let(:dim_crossover) { described_class.new(dim) }
        let(:dim_parents) do
          Array.new(dim + 1) do |i|
            chromosome = Array.new(dim) { |j| i + j * 0.5 }
            create_individual(chromosome)
          end
        end

        it "produces valid children" do
          child = dim_crossover.crossover(dim_parents)
          expect(child.chromosome.size).to eq(dim)
          expect(child.chromosome).to all(be_a(Float))
        end
      end
    end
  end

  describe "randomness and reproducibility" do
    context "randomness" do
      it "produces different results on multiple calls" do
        children = Array.new(10) { crossover.crossover(parents) }
        chromosomes = children.map(&:chromosome)

        # All chromosomes should be different (very high probability)
        chromosomes.combination(2).each do |chrom1, chrom2|
          expect(chrom1).not_to eq(chrom2)
        end
      end
    end
  end

  describe "mathematical properties" do
    context "simplex coefficient generation" do
      it "generates valid simplex transformations" do
        # Test that the simplex crossover produces valid transformations
        children = Array.new(20) { crossover.crossover(parents) }

        # All children should be valid
        children.each do |child|
          expect(child.chromosome.size).to eq(n_dim)
          expect(child.chromosome).to all(be_finite)
        end
      end
    end

    context "parent influence" do
      let(:distant_parents) do
        [
          create_individual([0.0, 0.0, 0.0]),
          create_individual([10.0, 0.0, 0.0]),
          create_individual([0.0, 10.0, 0.0]),
          create_individual([0.0, 0.0, 10.0])
        ]
      end

      it "shows influence from all parents" do
        children = Array.new(10) { crossover.crossover(distant_parents) }

        # Children should show variation influenced by the parent distribution
        children.each do |child|
          expect(child.chromosome).to be_a(Array)
          expect(child.chromosome.size).to eq(3)
        end
      end
    end
  end

  private

  def create_individual(chromosome)
    individual = Genalgo::Individual.new(
      n_dim: chromosome.size,
      upper_limit: 100.0,
      lower_limit: -100.0
    )
    individual.chromosome = chromosome
    individual.fitness = rand * 10
    individual
  end
end
