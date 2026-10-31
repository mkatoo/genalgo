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
      @params = params.to_h.dup
      self.seed = @params[:seed]
      self.crossover = @params[:crossover]
    end

    def seed=(value)
      @params[:seed] = value.nil? ? Configuration::DEFAULT_VALUES[:seed].call : value
    end

    def crossover=(value)
      @params[:crossover] = value.nil? ? Configuration::DEFAULT_VALUES[:crossover] : value
    end

    def complete?
      Configuration::REQUIRED_PARAMETERS.all? { |name| !@params[name].nil? }
    end

    def to_h
      @params.dup
    end

    def build
      Configuration.new(to_h)
    end
  end
end
