# frozen_string_literal: true

require_relative "bounds"

module Genalgo
  # Validated, immutable settings for a single execution.
  class Configuration
    PARAMETERS = %i[n_pop n_dim n_eval upper_limit lower_limit crossover seed evaluation_function].freeze
    REQUIRED_PARAMETERS = %i[n_pop n_dim n_eval upper_limit lower_limit evaluation_function].freeze
    DEFAULT_VALUES = { crossover: :blx_alpha, seed: -> { Random.new_seed } }.freeze

    attr_reader :bounds, :bounds_object

    PARAMETERS.each do |name|
      define_method(name) { @params[name] }
    end

    def initialize(params = {})
      @params = params.slice(*PARAMETERS)
      @params[:crossover] ||= DEFAULT_VALUES[:crossover]
      @params[:seed] ||= DEFAULT_VALUES[:seed].call
      validate_required_parameters!
      @bounds_object = Bounds.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)
      validate_all_parameters!
      @bounds = { upper: upper_limit, lower: lower_limit }.freeze
      @params.freeze
      freeze
    end

    def self.build(params = {})
      new(params)
    end

    def to_h
      @params.dup
    end

    def complete?
      REQUIRED_PARAMETERS.all? { |name| !@params[name].nil? }
    end

    def validate_all_parameters!
      validate_positive_integers!
      validate_interfaces!
      validate_dependencies!
    end

    alias validate_before_execution! validate_all_parameters!

    private

    def validate_required_parameters!
      missing = REQUIRED_PARAMETERS.select { |name| @params[name].nil? }
      validate!(missing.empty?, "Missing required parameters: #{missing.join(", ")}",
                missing_parameters: missing, provided_parameters: @params.keys)
    end

    def validate_positive_integers!
      %i[n_pop n_eval].each do |name|
        value = @params[name]
        validate!(value.is_a?(Integer) && value.positive?, "#{name} must be a positive integer, got #{value.inspect}",
                  parameter: name, value: value, minimum_value: 1)
      end
    end

    def validate_interfaces!
      validate!(seed.is_a?(Integer), "Seed must be an integer, got #{seed.class}", parameter: :seed, value: seed)
      validate!(evaluation_function.respond_to?(:call), "Evaluation function must be callable",
                parameter: :evaluation_function, expected_interface: "callable")
      validate!(%i[blx_alpha simplex].include?(crossover), "Unknown crossover type: #{crossover}",
                crossover: crossover, valid_types: %i[blx_alpha simplex])
    end

    def validate_dependencies!
      minimum_population = crossover == :simplex ? n_dim + 1 : 2
      validate!(n_pop >= minimum_population,
                "#{crossover} crossover requires population size >= #{minimum_population}, got #{n_pop}",
                crossover: crossover, n_dim: n_dim, n_pop: n_pop, minimum_population: minimum_population)
      validate_evaluation_budget!
    end

    def validate_evaluation_budget!
      validate!(n_eval >= n_pop, "Evaluation budget (#{n_eval}) must cover the initial population (#{n_pop})",
                n_eval: n_eval, n_pop: n_pop)
    end

    def validate!(valid, message, **context)
      raise ConfigurationError.new(message, context: context) unless valid
    end
  end
end
