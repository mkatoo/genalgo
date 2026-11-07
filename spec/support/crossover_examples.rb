# frozen_string_literal: true

RSpec.shared_examples "a bounded immutable crossover" do
  it "is immutable and leaves parents untouched when offspring is changed" do
    original = parents.map(&:dup)
    crossover.call(parents, bounds: bounds, random: random).fill(999)

    expect(parents).to eq(original)
    expect(crossover).to be_frozen
  end

  it "preserves identical parents as floating point coordinates" do
    identical = Array.new(crossover.parent_count(bounds.dimension)) { parents.first }
    child = crossover.call(identical, bounds: bounds, random: random)

    expect(child).to eq(parents.first.map(&:to_f))
    expect(child).to all(be_a(Float))
  end

  it "reproduces varied, bounded offspring using only the supplied random stream" do
    first = Array.new(5) { crossover.call(parents, bounds: bounds, random: random) }
    other_random = Random.new(123)
    second = Array.new(5) { crossover.call(parents, bounds: bounds, random: other_random) }

    expect(first).to eq(second)
    expect(random.rand).to eq(other_random.rand)
    expect(first.uniq.size).to be > 1
    expect(first).to all(satisfy { |genes| bounds.within_bounds?(genes) })
  end

  it "samples prepared parents with the same offspring and random consumption as repeated calls" do
    sampler = crossover.prepare(parents, bounds: bounds)
    other_random = Random.new(123)
    expected = Array.new(5) { crossover.call(parents, bounds: bounds, random: random) }
    actual = Array.new(5) { sampler.call(random: other_random) }

    expect(actual).to eq(expected)
    expect(other_random.rand).to eq(random.rand)
    expect(sampler).to be_frozen
  end

  it "keeps prepared parents independent of input changes, other preparations, and earlier offspring" do
    sampler = crossover.prepare(parents, bounds: bounds)
    expected = sampler.call(random: Random.new(123))
    parents.each { |parent| parent.fill(999) }
    other_parents = Array.new(crossover.parent_count(bounds.dimension)) { bounds.lower }
    crossover.prepare(other_parents, bounds: bounds).call(random: random)
    sampler.call(random: random).fill(999)

    expect(sampler.call(random: Random.new(123))).to eq(expected)
  end

  it "rejects invalid parents before returning a prepared sampler" do
    expect { crossover.prepare([], bounds: bounds) }.to raise_error(Genalgo::StrategyError)
  end
end
