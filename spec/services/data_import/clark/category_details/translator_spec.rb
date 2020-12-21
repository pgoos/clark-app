# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataImport::Clark::CategoryDetails::Translator do
  subject { described_class.new(csv) }

  let(:record) do
    {
      id: "CAT-1",
      category_name: "test name",
      ident: "c1bfed3a",
      category_type: "regular",
      respective_umbrella: "test respective umbrella",
      top_5_most_frequent_categories: "no",
      visible_in_category_selection: "no",
      expert_tip_1: "tip 1",
      expert_tip_2: "tip 2",
      expert_tip_3: "tip 3",
      "cover_benchmark_(%_of_austrians)": "35%",
      "translation_(one_senetence_description": "testing description",
      life_aspect: "Gesundheit & Existenz",
      high_margin_or_low_margin?: "high margin",
      search_terms: "test, test2, test3, testing",
      buyable_category: "no",
      priority: "12",
      questionnaire_ident: "test ident",
      general_description: "general description",
      "3_benefits": "* benefit 1\n* benefit 2\n* benefit 3",
      typical_claim: "claim",
      why_clark: "* guideline 1\n* guideline 2\n* guideline 3",
      clark_guarantee: "* warranty 1\n* warranty 2\n* warranty 3"
    }
  end
  let(:csv) { [record] }

  describe "#call" do
    let(:result) { subject.call.first }

    it "translates column names" do
      expect(result.keys)
        .to include(:name, :customer_description, :consultant_comment, :benefits, :what_happens_if)
      expect(result.keys)
        .not_to include(:category_name, :general_description, "3_benefits", :typical_claim)
    end

    context "transforms values" do
      it "transform lists to arrays" do
        expect(result[:benefits])
          .to eq ["benefit 1", "benefit 2", "benefit 3"]
      end
    end

    it "return only allowed columns" do
      expect(result.keys).to match_array(described_class::ALLOWED_COLUMNS)
    end
  end
end
