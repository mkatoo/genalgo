# frozen_string_literal: true

require "json"
require_relative "../lib/genalgo"

def measure(configuration)
  GC.start
  allocated = GC.stat(:total_allocated_objects)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  Genalgo::Optimizer.new(configuration).run { |genes| genes.sum { |gene| gene * gene } }
  { seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
    allocations: GC.stat(:total_allocated_objects) - allocated }
end

measurements = [Genalgo::Crossovers::BlxAlpha.new, Genalgo::Crossovers::Simplex.new].flat_map do |crossover|
  [[100, 10, 2100], [500, 30, 2500]].map do |size, dimension, budget|
    bounds = Genalgo::Bounds.new(lower: Array.new(dimension, -5.0), upper: Array.new(dimension, 5.0))
    configuration = Genalgo::Configuration.new(bounds: bounds, population_size: size,
                                               max_evaluations: budget, crossover: crossover, seed: 123)
    runs = Array.new(3) { measure(configuration) }
    { crossover: crossover.class.name, population: size, dimensions: dimension, budget: budget,
      seconds: runs.map { |run| run[:seconds] }.sort[1], allocations: runs.map { |run| run[:allocations] }.sort[1] }
  end
end

puts JSON.pretty_generate(ruby: RUBY_DESCRIPTION, repetitions: 3, measurements: measurements)
