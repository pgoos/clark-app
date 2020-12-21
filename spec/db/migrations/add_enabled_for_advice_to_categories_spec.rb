# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "add_enabled_for_advice_to_categories"

RSpec.describe AddEnabledForAdviceToCategories, :integration do
  describe "#data" do
    context "with enabled category" do
      let!(:category) { create :category_phv, enabled_for_advice: false }

      it do
        described_class.new.data
        expect(category.reload).to be_enabled_for_advice
      end
    end

    context "without enabled category" do
      let!(:category) { create :category, ident: "another_category", enabled_for_advice: false }

      it do
        described_class.new.data
        expect(category.reload).not_to be_enabled_for_advice
      end
    end
  end
end
