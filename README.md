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

## License

MIT
