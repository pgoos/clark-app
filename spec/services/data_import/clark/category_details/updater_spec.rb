# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataImport::Clark::CategoryDetails::Updater do
  subject { described_class.new(parsed_csv) }

  let!(:category1) { create(:category, name: "test") }
  let!(:category2) { create(:category, name: "test 2") }
  let!(:questionnaire1) { create(:questionnaire, identifier: "testident") }
  let!(:questionnaire2) { create(:questionnaire) }
  let(:record1) do
    {
      name: "test",
      ident: "c1bfed3a",
      questionnaire_ident: "testident",
      customer_description: "customer description 1",
      benefits: ["benefit 1", "benefit 2", "benefit 3"],
      what_happens_if: "test claim"
    }
  end
  let(:record2) do
    {
      name: "test 2",
      ident: "bac23c6c",
      questionnaire_ident: "testident2",
      customer_description: "customer description 1",
      benefits: ["benefit 1", "benefit 2", "benefit 3"],
      what_happens_if: "test claim"
    }
  end
  let(:parsed_csv) { [record1, record2] }

  describe "#call" do
    before { subject.call }

    it "updates existing categories" do
      expect(category1.reload)
        .to have_attributes(record1.except(:questionnaire_ident))
      expect(category2.reload)
        .to have_attributes(record2.except(:questionnaire_ident))
    end

    it "assigns questionnaire if found" do
      expect(category1.reload.questionnaire.id).to eq questionnaire1.id
      expect(category2.reload.questionnaire).to eq nil
    end
  end
end
