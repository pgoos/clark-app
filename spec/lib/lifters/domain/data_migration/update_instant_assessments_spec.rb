# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataMigration::UpdateInstantAssessments do
  describe "#call" do
    let!(:instant_assessment_1) do
      create(:instant_assessment, category_ident: "3659e48a", company_ident: "knappebde3f", popularity: { value: 10 })
    end
    let!(:instant_assessment_2) do
      create(:instant_assessment, category_ident: "test", company_ident: "test2", popularity: { value: 15 })
    end

    it "updates InstantAssessments" do
      described_class.call
      expect(instant_assessment_1.reload.popularity["value"]).to eq 90
      expect(instant_assessment_1.reload.popularity["description"]).to eq instant_assessment_1.popularity["description"]
      expect(instant_assessment_2.reload.popularity["value"]).to eq 15
    end
  end
end
