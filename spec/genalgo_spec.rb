# frozen_string_literal: true

RSpec.describe Genalgo do
  it "has a version number" do
    expect(Genalgo::VERSION).not_to be nil
  end

  describe "module constants" do
    it "defines the main module" do
      expect(defined?(Genalgo)).to eq("constant")
    end

    it "defines the Error class" do
      expect(defined?(Genalgo::Error)).to eq("constant")
      expect(Genalgo::Error).to be < StandardError
    end
  end
end
