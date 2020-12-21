# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::AdminPerformanceClassificationsRepository,
               :integration do
  let(:repository) { described_class.new }

  describe "#performance_classifications" do
    let!(:admin) { create(:admin) }
    let!(:other_admin) { create(:admin) }
    let!(:category) { create(:category) }
    let!(:other_category) { create(:category) }
    let!(:classifications) do
      [
        create(:admin_performance_classification, admin: admin, category: category, level: "a"),
        create(:admin_performance_classification, admin: admin, category: other_category, level: "c"),
        create(:admin_performance_classification, admin: other_admin, category: category, level: "b"),
        create(:admin_performance_classification, admin: create(:admin), category: category, level: "b")
      ]
    end

    it "returns valid performance classifications" do
      expect(
        repository.performance_classifications([admin.id, other_admin.id])
      ).to eq(
        admin.id       => { performance_level: { category.ident => "a", other_category.ident => "c" } },
        other_admin.id => { performance_level: { category.ident => "b" } }
      )
    end
  end
end
