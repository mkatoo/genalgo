# frozen_string_literal: true

module Genalgo
  # Samples finite intervals without computing a potentially overflowing width.
  module IntervalSampling
    module_function

    def sample(lower, upper, random:)
      fraction = random.rand
      lower == upper ? lower : (lower * (1.0 - fraction)) + (upper * fraction)
    end
  end

  private_constant :IntervalSampling
end
