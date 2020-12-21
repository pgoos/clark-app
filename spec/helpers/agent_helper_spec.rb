# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgentHelper do
  describe ".address" do
    let(:expected_format) do
      "Clark Germany GmbH | Wilhelm-Leuschner-Str. 17-19, 60329 Frankfurt"
    end

    it "formats string from Settings in the correct order" do
      expect(AgentHelper.address).to eq expected_format
    end
  end
end
