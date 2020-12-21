# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe Roboadvisor, type: :integration do
  describe ".process" do
    subject { described_class.process(product.id) }

    let(:product) { create :product }

    let(:rules) do
      [
        Roboadvisor::Rule.new(
          rule_id: "RULE1",
          expression: ->(_) { true }
        ),
        Roboadvisor::Rule.new(
          rule_id: "RULE2",
          expression: ->(_) { true }
        )
      ]
    end

    before do
      repo = object_double Roboadvisor::RuleRepository.new, for_product: rules
      allow(Roboadvisor::RuleRepository).to receive(:new).and_return repo
    end

    it "returns first succeeded rule by default" do
      rule_id = described_class.process(product.id)
      expect(rule_id).to eq "RULE1"
    end

    context "with rule_ids" do
      it "skips the rules which are not in the given list" do
        rule_id = described_class.process(product.id, %i[RULE2])
        expect(rule_id).to eq "RULE2"
      end
    end
  end
end
