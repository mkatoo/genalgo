# frozen_string_literal: true

require_relative "configuration"

module Genalgo
  # MutableConfiguration provides a wrapper around Configuration that allows
  # modification of parameters while maintaining validation and encapsulation
  # without using reflection methods like instance_variable_set
  class MutableConfiguration
    def initialize(params = {})
      @params = params.dup
      @configuration = nil
      rebuild_configuration
    end

    # Delegate read methods to the current configuration
    def n_pop
      @configuration.n_pop
    end

    def n_dim
      @configuration.n_dim
    end

    def n_eval
      @configuration.n_eval
    end

    def upper_limit
      @configuration.upper_limit
    end

    def lower_limit
      @configuration.lower_limit
    end

    def crossover
      @configuration.crossover
    end

    def seed
      @configuration.seed
    end

    def evaluation_function
      @configuration.evaluation_function
    end

    def bounds
      @configuration.bounds
    end

    def bounds_object
      @configuration.bounds_object
    end

    def complete?
      @configuration.complete?
    end

    def to_h
      @configuration.to_h
    end

    def validate_before_execution!
      @configuration.validate_before_execution!
    end

    def validate_all_parameters!
      @configuration.validate_all_parameters!
    end

    # Mutable setters - these rebuild the configuration when values change
    def n_pop=(value)
      @params[:n_pop] = value
      rebuild_configuration
    end

    def n_dim=(value)
      @params[:n_dim] = value
      rebuild_configuration
    end

    def n_eval=(value)
      @params[:n_eval] = value
      rebuild_configuration
    end

    def upper_limit=(value)
      @params[:upper_limit] = value
      rebuild_configuration
    end

    def lower_limit=(value)
      @params[:lower_limit] = value
      rebuild_configuration
    end

    def crossover=(value)
      @params[:crossover] = value
      rebuild_configuration
    end

    def seed=(value)
      @params[:seed] = value
      rebuild_configuration
    end

    def evaluation_function=(value)
      @params[:evaluation_function] = value
      rebuild_configuration
    end

    private

    def rebuild_configuration
      @configuration = Configuration.new(@params, strict: false, freeze: false)
    end
  end
end