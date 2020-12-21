# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe Roboadvisor::Coverage do
  describe "attributes" do
    let(:key) { "dckng7eecd7eff390d702" }
    let(:value) { "100" }

    it do
      coverage = described_class.new(key: key, value: value)
      expect(coverage.key).to eq key
      expect(coverage.value).to eq value.to_f
    end
  end
end
