# frozen_string_literal: true

require_relative "configuration"

module Genalgo
  # Editable input that produces an independent Configuration when built.
  class MutableConfiguration
    Configuration::PARAMETERS.each do |name|
      define_method(name) { @params[name] }
    end

    (Configuration::PARAMETERS - %i[seed crossover]).each do |name|
      define_method("#{name}=") { |value| @params[name] = value }
    end

    def initialize(params = {})
      @params = params.to_h.slice(*Configuration::PARAMETERS)
      self.seed = @params[:seed]
      self.crossover = @params[:crossover]
    end

    def seed=(value)
      @params[:seed] = value.nil? ? Configuration::DEFAULT_VALUES[:seed].call : value
    end

    def crossover=(value)
      @params[:crossover] = value.nil? ? Configuration::DEFAULT_VALUES[:crossover] : value
    end

    def bounds
      { upper: upper_limit, lower: lower_limit }
    end

    def bounds_object
      Bounds.new(n_dim: n_dim, upper_limit: upper_limit, lower_limit: lower_limit)
    end

    def complete?
      Configuration::REQUIRED_PARAMETERS.all? { |name| !@params[name].nil? }
    end

    def to_h
      Configuration::PARAMETERS.to_h { |name| [name, @params[name]] }
    end

    def build
      Configuration.new(to_h)
    end

    alias validate_before_execution! build
    alias validate_all_parameters! build
  end
end
