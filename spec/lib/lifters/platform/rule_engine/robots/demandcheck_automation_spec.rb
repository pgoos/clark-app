# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Platform::RuleEngineV3::Robots::DemandcheckAutomation do
  let(:subject) { described_class.new }

  context "#candidates" do
    let!(:mandate) { create(:mandate, state: "accepted") }
    let!(:mandate_n27) { create(:mandate, state: "accepted") }

    before do
      mandate_n27.update(owner_ident: "n27")
    end

    it "include all mandates" do
      expect(subject.candidates).to include(mandate)
    end

    it "does not include partner mandates" do
      expect(subject.candidates).not_to include(mandate_n27)
    end
  end
end
