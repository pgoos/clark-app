# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Recommendations::Constituents::Overview::Repositories::CategoryRepository, :integration do
  let(:category) { create(:category) }

  describe ".find_attributes" do
    context "when category_id is passed in" do
      it "returns category attributes" do
        attributes = described_class.new.find_attributes(category.id)
        expected_attributes = {
          id: category.id,
          ident: category.ident,
          name: category.name,
          description: category.description,
          life_aspect: category.life_aspect,
          questionnaire_ident: nil,
          priority: category.priority,
          page_available: false,
          benefits: nil,
          consultant_comment: nil
        }

        expect(attributes).to eq(expected_attributes)
      end
    end
  end
end
