# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # Validated, immutable settings for a single execution.
  class Configuration
    PARAMETERS = %i[n_pop n_eval bounds crossover seed evaluation_function].freeze
    REQUIRED_PARAMETERS = %i[n_pop n_eval bounds evaluation_function].freeze
    DEFAULT_VALUES = { crossover: :blx_alpha, seed: -> { Random.new_seed } }.freeze
    CROSSOVERS = %i[blx_alpha simplex].freeze

    PARAMETERS.each do |name|
      define_method(name) { @params[name] }
    end

    def initialize(params = {})
      @params = params.to_h.dup
      validate_known_parameters!
      apply_defaults!
      validate_required_parameters!
      validate_parameters!
      @params.freeze
      freeze
    end

    def n_dim
      bounds.n_dim
    end

    def to_h
      @params.dup
    end

    private

    def apply_defaults!
      @params[:crossover] = DEFAULT_VALUES[:crossover] if crossover.nil?
      @params[:seed] = DEFAULT_VALUES[:seed].call if seed.nil?
    end

    def validate_known_parameters!
      unknown = @params.keys - PARAMETERS
      validate!(unknown.empty?, "Unknown parameters: #{unknown.join(", ")}", unknown_parameters: unknown)
    end

    def validate_required_parameters!
      missing = REQUIRED_PARAMETERS.select { |name| @params[name].nil? }
      validate!(missing.empty?, "Missing required parameters: #{missing.join(", ")}", missing_parameters: missing)
    end

    def validate_parameters!
      validate_positive_integers!
      validate_interfaces!
      validate_population_size!
      validate!(n_eval >= n_pop, "Evaluation budget (#{n_eval}) must cover the initial population (#{n_pop})",
                n_eval: n_eval, n_pop: n_pop)
    end

    def validate_positive_integers!
      %i[n_pop n_eval].each do |name|
        value = @params[name]
        validate!(value.is_a?(Integer) && value.positive?, "#{name} must be a positive integer, got #{value.inspect}",
                  parameter: name, value: value, minimum_value: 1)
      end
    end

    def validate_interfaces!
      validate!(bounds.is_a?(Bounds), "Bounds must be a Genalgo::Bounds instance", parameter: :bounds)
      validate!(seed.is_a?(Integer), "Seed must be an integer", parameter: :seed, value: seed)
      validate!(evaluation_function.respond_to?(:call), "Evaluation function must be callable",
                parameter: :evaluation_function)
      validate!(CROSSOVERS.include?(crossover), "Unknown crossover type: #{crossover}", crossover: crossover)
    end

    def validate_population_size!
      minimum_population = crossover == :simplex ? n_dim + 1 : 2
      validate!(n_pop >= minimum_population,
                "#{crossover} crossover requires population size >= #{minimum_population}, got #{n_pop}",
                crossover: crossover, n_dim: n_dim, n_pop: n_pop, minimum_population: minimum_population)
    end

    def validate!(valid, message, **context)
      raise ConfigurationError.new(message, context: context) unless valid
    end
  end
end
