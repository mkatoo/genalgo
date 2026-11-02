# frozen_string_literal: true

module Genalgo
  # Shared predicates for finite real values within the Float range.
  module NumericValidation
    module_function

    def finite_real?(value)
      return value.finite? if value.is_a?(Float)

      value.is_a?(Numeric) && value.real? && value.finite? && value.abs <= Float::MAX
    end
  end

  private_constant :NumericValidation
end
