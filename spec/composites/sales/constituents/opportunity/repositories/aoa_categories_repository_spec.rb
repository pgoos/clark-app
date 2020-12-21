# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::AoaCategoriesRepository, :integration do
  describe "#select_categories_used_in_aoa" do
    context "find only high and medium categories" do
      let!(:high_margin_category) { create :category, :high_margin }
      let!(:medium_margin_category) { create :category, :medium_margin }
      let!(:low_margin_category) { create :category, :low_margin }

      it "returns category ids" do
        expect(subject.select_categories_used_in_aoa).to match_array(
          [high_margin_category.id, medium_margin_category.id]
        )
      end
    end
  end
end
