# Genalgo

Real-Coded Genetic Algorithm

Generation Alternation Model: Minimal Generation Gap (MGG)

Crossover: BLX-alpha, Simplex

## Installation

Include the gem to your Gemfile:

```ruby
gem "genalgo", github: "mkatoo/genalgo"
```

Then run Bundler:

```
$ bundle install
```

## Usage

```ruby
require 'genalgo'

# Evaluation Function
def sphere(x)
  x.sum { |xi| xi ** 2 }
end

executor = Genalgo::Executor.new
executor.n_pop = 100
executor.n_dim = 10
executor.n_eval = 10000
executor.upper_limit = 100.0
executor.lower_limit = -100.0
executor.evaluation_function = lambda { |x| sphere(x) }
executor.crossover = :blx_alpha

executor.execute

executor.history.last.best_individual
```

## Configuration

`Executor` accepts a hash, a `MutableConfiguration`, or a complete `Configuration`.
Its setters and `executor.configuration` edit the input for the next execution.
Each call to `execute` validates that input and builds an independent, immutable
snapshot available as `executor.execution_configuration`. Changes made during an
evaluation take effect on the next execution. If validation fails, the previous
execution's results and snapshot remain available.

Each execution creates one `MGG` instance from its validated configuration and
reuses it for all generation updates. To control generation updates directly,
create `random = Random.new(configuration.seed)` and pass that same generator to
both `Population.new` and `MGG.new(configuration, random: random)` through the
`random:` keyword. Evaluate the initial population, then call
`next_generation(population)` on the MGG instance. Generation settings belong to
each instance; there are no class-level settings.

Use `MutableConfiguration` to prepare settings incrementally:

```ruby
input = Genalgo::MutableConfiguration.new(
  n_pop: 100, n_dim: 10, n_eval: 10000,
  lower_limit: -100.0, upper_limit: 100.0
)
input.evaluation_function = ->(x) { x.sum { |xi| xi ** 2 } }
input.seed = 12345

configuration = input.build
executor = Genalgo::Executor.new(configuration)
executor.execute
executor.execution_configuration.seed # => 12345
```

`Configuration.new(params)` and `Configuration.build(params)` validate immediately
and always freeze the configuration and its bounds. Incomplete input belongs in
`MutableConfiguration`; the former `strict:` and `freeze:` options are no longer
supported. Input hashes and settings passed to `Executor` are copied. The supplied
evaluation callable is retained by reference.

An omitted seed is generated once and retained across unrelated edits and repeated
executions. Assigning a new seed explicitly, or assigning `nil` to generate one,
changes it for subsequent executions.

Each execution uses its own random stream for initialization, parent sampling,
crossover, and selection. Global `rand`/`srand` calls and other executors do not
affect that stream. Genalgo does not advance or reseed the global stream.
Reproducibility assumes a deterministic evaluation function; a stochastic
evaluation function controls its own randomness.

The evaluation budget must cover the initial population (`n_eval >= n_pop`).
BLX-alpha requires at least 2 individuals; Simplex requires at least `n_dim + 1`.
Dimensions must be positive integers, and bounds must be finite real numbers with
`lower_limit <= upper_limit`. Equal bounds fix every coordinate to that value.
Invalid settings raise `Genalgo::ConfigurationError` before any evaluation.

## License

MIT
