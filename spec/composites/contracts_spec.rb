# frozen_string_literal: true

require "rails_helper"
require "composites/contracts"

RSpec.describe Contracts do
  describe "#instant_advice", :integration do
    let!(:instant_assessment) { create(:instant_assessment) }

    it "returns instant advice" do
      result = described_class.instant_advice(instant_assessment.category_ident, instant_assessment.company_ident)
      expect(result).to be_a(Utils::Interactor::Result)
      expect(result.instant_advice).to be_a(Contracts::Constituents::InstantAdvice::Entities::InstantAdvice)
    end
  end
end
