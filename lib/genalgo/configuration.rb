# frozen_string_literal: true

module Genalgo
  class Configuration
    attr_reader :n_pop, :n_dim, :n_eval, :upper_limit, :lower_limit,
                :crossover, :seed, :evaluation_function

    DEFAULT_VALUES = {
      crossover: :blx_alpha,
      seed: -> { Random.new_seed }
    }.freeze

    REQUIRED_PARAMETERS = %i[n_pop n_dim n_eval upper_limit lower_limit evaluation_function].freeze

    def initialize(params = {}, strict: false, freeze: true)
      @params = params.dup
      @strict = strict
      @freeze = freeze
      set_defaults
      validate_all_parameters! if @strict
      freeze_configuration if @freeze
    end

    def self.build(params = {})
      new(params)
    end

    def bounds
      @bounds ||= { upper: @upper_limit, lower: @lower_limit }
    end

    def bounds_object
      @bounds_object ||= Bounds.new(
        n_dim: @n_dim,
        upper_limit: @upper_limit,
        lower_limit: @lower_limit
      )
    end

    def complete?
      [@n_pop, @n_dim, @n_eval, @upper_limit, @lower_limit, @evaluation_function].all?
    end

    def validate_all_parameters!
      validate_required_parameters!
      validate_parameter_types!
      validate_parameter_values!
      validate_parameter_dependencies!
    end

    def validate_before_execution!
      return if @strict

      validate_all_parameters!
    end

    def to_h
      {
        n_pop: @n_pop,
        n_dim: @n_dim,
        n_eval: @n_eval,
        upper_limit: @upper_limit,
        lower_limit: @lower_limit,
        crossover: @crossover,
        seed: @seed,
        evaluation_function: @evaluation_function
      }
    end

    private

    def set_defaults
      @n_pop = @params[:n_pop]
      @n_dim = @params[:n_dim]
      @n_eval = @params[:n_eval]
      @upper_limit = @params[:upper_limit]
      @lower_limit = @params[:lower_limit]
      @evaluation_function = @params[:evaluation_function]

      @crossover = @params[:crossover] || DEFAULT_VALUES[:crossover]
      @seed = @params[:seed] || DEFAULT_VALUES[:seed].call
    end

    def freeze_configuration
      freeze
      @params.freeze
    end

    def validate_required_parameters!
      missing_params = []
      missing_params << :n_pop unless @n_pop
      missing_params << :n_dim unless @n_dim
      missing_params << :n_eval unless @n_eval
      missing_params << :upper_limit unless @upper_limit
      missing_params << :lower_limit unless @lower_limit
      missing_params << :evaluation_function unless @evaluation_function

      return if missing_params.empty?

      raise ConfigurationError.new(
        "Missing required parameters: #{missing_params.join(", ")}",
        context: { missing_parameters: missing_params, provided_parameters: @params.keys }
      )
    end

    def validate_parameter_types!
      validate_integer_parameter(@n_pop, :n_pop, "Population size") if @n_pop
      validate_integer_parameter(@n_dim, :n_dim, "Dimension") if @n_dim
      validate_integer_parameter(@n_eval, :n_eval, "Evaluation count") if @n_eval
      validate_numeric_parameter(@upper_limit, :upper_limit, "Upper limit") if @upper_limit
      validate_numeric_parameter(@lower_limit, :lower_limit, "Lower limit") if @lower_limit
      validate_callable_parameter(@evaluation_function, :evaluation_function, "Evaluation function") if @evaluation_function
      validate_crossover_type if @crossover
      validate_seed_type if @seed
    end

    def validate_parameter_values!
      validate_positive_parameter(@n_pop, :n_pop, "Population size") if @n_pop
      validate_positive_parameter(@n_dim, :n_dim, "Dimension") if @n_dim
      validate_positive_parameter(@n_eval, :n_eval, "Evaluation count") if @n_eval
      validate_bounds_order if @upper_limit && @lower_limit
    end

    def validate_parameter_dependencies!
      validate_simplex_crossover_requirements if @crossover == :simplex && @n_dim && @n_pop
    end

    def validate_integer_parameter(value, param_name, display_name)
      return if value.is_a?(Integer)

      raise ConfigurationError.new(
        "#{display_name} must be an integer, got #{value.class}",
        context: { parameter: param_name, value: value, expected_type: "Integer" }
      )
    end

    def validate_numeric_parameter(value, param_name, display_name)
      return if value.is_a?(Numeric)

      raise ConfigurationError.new(
        "#{display_name} must be numeric, got #{value.class}",
        context: { parameter: param_name, value: value, expected_type: "Numeric" }
      )
    end

    def validate_callable_parameter(value, param_name, display_name)
      return if value.respond_to?(:call)

      raise ConfigurationError.new(
        "#{display_name} must be callable (respond to :call), got #{value.class}",
        context: { parameter: param_name, value: value, expected_interface: "callable" }
      )
    end

    def validate_positive_parameter(value, param_name, display_name)
      return if value&.positive?

      raise ConfigurationError.new(
        "#{display_name} must be positive, got #{value}",
        context: { parameter: param_name, value: value, minimum_value: 1 }
      )
    end

    def validate_crossover_type
      valid_types = %i[blx_alpha simplex]
      return if valid_types.include?(@crossover)

      raise ConfigurationError.new(
        "Crossover type must be one of #{valid_types}, got #{@crossover}",
        context: { crossover: @crossover, valid_types: valid_types }
      )
    end

    def validate_seed_type
      return if @seed.is_a?(Integer)

      raise ConfigurationError.new(
        "Seed must be an integer, got #{@seed.class}",
        context: { seed: @seed, expected_type: "Integer" }
      )
    end

    def validate_bounds_order
      return unless @upper_limit <= @lower_limit

      raise ConfigurationError.new(
        "Upper limit (#{@upper_limit}) must be greater than lower limit (#{@lower_limit})",
        context: { upper_limit: @upper_limit, lower_limit: @lower_limit }
      )
    end

    def validate_simplex_crossover_requirements
      min_population = @n_dim + 1
      return if @n_pop >= min_population

      raise ConfigurationError.new(
        "Simplex crossover requires population size >= n_dim + 1 " \
        "(#{min_population} for #{@n_dim}D), got #{@n_pop}",
        context: {
          crossover: @crossover,
          n_dim: @n_dim,
          n_pop: @n_pop,
          minimum_population: min_population
        }
      )
    end
  end
end
