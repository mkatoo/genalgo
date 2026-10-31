# Genalgo

Real-coded genetic algorithms with the Minimal Generation Gap (MGG) model.
Supports BLX-alpha and Simplex crossover.

## Installation

Add the gem to your Gemfile:

```ruby
gem "genalgo", github: "mkatoo/genalgo"
```

Then run `bundle install`.

## Usage

```ruby
require "genalgo"

bounds = Genalgo::Bounds.new(
  lower: Array.new(10, -100.0),
  upper: Array.new(10, 100.0)
)
executor = Genalgo::Executor.new(
  n_pop: 100,
  n_eval: 10000,
  bounds: bounds,
  evaluation_function: ->(x) { x.sum { |gene| gene * gene } },
  crossover: :blx_alpha,
  seed: 12345
)

executor.execute
executor.best_individual
executor.history.last.evaluations
```

Fitness is minimized. History records an independent copy of the best individual
and the cumulative evaluation count after initialization and each generation.

## Coordinate bounds

`Bounds` holds a separate interval for every coordinate:

```ruby
bounds = Genalgo::Bounds.new(
  lower: [-5.0, 10.0, 3.0],
  upper: [5.0, 20.0, 3.0]
)
bounds.n_dim # => 3
```

Here the first coordinate ranges from -5 to 5, the second from 10 to 20, and the
third is fixed at 3. The dimension comes from the array length; it is never set
separately. Both arrays must be non-empty, have equal lengths, and contain finite
real numbers. Each lower bound must be less than or equal to its upper bound.

Bounds copies and freezes its input arrays. Initialization and crossover respect
each coordinate's interval. Individuals receive a `Bounds` object and a chromosome;
they copy and clamp the chromosome, rejecting incorrect lengths or non-finite
coordinates.

## Configuration

`Executor` accepts a settings hash, a `MutableConfiguration`, or a validated
`Configuration`. Use `executor.configuration` to edit settings for the next run:

```ruby
input = Genalgo::MutableConfiguration.new(n_pop: 100, n_eval: 10000)
input.bounds = Genalgo::Bounds.new(lower: [-5.0, 10.0, 3.0], upper: [5.0, 20.0, 3.0])
input.evaluation_function = ->(x) { x.sum { |gene| gene * gene } }
input.seed = 12345

configuration = input.build
executor = Genalgo::Executor.new(configuration)
executor.configuration.n_eval = 20000
executor.execute
executor.execution_configuration.n_dim # => 3
```

`Configuration.new(params)` validates immediately and freezes the settings.
`MutableConfiguration#build` validates editable input and creates that immutable
snapshot. Unknown settings are rejected. Assign a new `Bounds` object to
`executor.configuration.bounds` to change intervals or the dimension together.

Each `execute` validates pending settings before replacing previous results. The
snapshot used by the run is available as `executor.execution_configuration`.
Changes to pending settings during evaluation take effect on the next execution.
Input settings are copied; immutable bounds can be shared safely. The evaluation
callable is retained by reference.

The evaluation budget must cover the initial population (`n_eval >= n_pop`).
BLX-alpha requires at least 2 individuals; Simplex requires at least `bounds.n_dim + 1`.
Each generation evaluates two children. A remaining budget of one evaluation is
left unused. Invalid settings raise `Genalgo::ConfigurationError` before evaluation.

An omitted seed is generated once and retained across unrelated edits and repeated
executions. Assign a new seed, or assign `nil` to generate one, to change subsequent
runs. Each execution uses its own random stream for initialization, parent
sampling, crossover, and selection. Global `rand`/`srand` calls and other executors
do not affect that stream. Genalgo does not advance or reseed the global stream.
Reproducibility assumes a deterministic evaluation function; a stochastic
function controls its own randomness.

## Direct generation control

`Executor` creates one `MGG` instance per execution and reuses it for all updates.
For direct control, pass the same random generator to population creation and MGG,
and evaluate the initial population before advancing it:

```ruby
configuration = input.build
random = Random.new(configuration.seed)
population = Genalgo::Population.new(
  n_pop: configuration.n_pop, bounds: configuration.bounds, random: random
)
population.each do |individual|
  individual.fitness = configuration.evaluation_function.call(individual.chromosome)
end

generation = Genalgo::MGG.new(configuration, random: random)
population = generation.next_generation(population)
```

## License

MIT
