# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "create_dummy_plans_for_umbrella_categories"

RSpec.describe CreateDummyPlansForUmbrellaCategories, :integration do
  subject { described_class.new }

  describe "#up" do
    let!(:categories) do
      [
        create(:category, :active, :umbrella, ident: "b8f222d1"),
        create(:category, :active, :umbrella, ident: "99081fc8"),
        create(:category, :active, :umbrella),
        create(:category, :active, :regular),
        create(:category, :inactive, :umbrella),
        create(:category, :active, :umbrella, ident: "1ded8a0f"),
        create(:umbrella_category, vertical: verticals[0], included_category_ids: [create(:category).id]),
        create(:umbrella_category, vertical: verticals[0], included_category_ids: [create(:category).id]),
        create(:umbrella_category, vertical: verticals[1], included_category_ids: [create(:category).id])
      ]
    end
    let!(:plans_to_remove) do
      [
        create(:plan, category: categories[1]),
        create(:plan, category: categories[5])
      ]
    end
    let!(:verticals) { create_list(:vertical, 2) }
    let!(:companies) { create_list(:company, 3) }
    let!(:subcompanies) do
      [
        create(:subcompany, verticals: [verticals[0]], company: companies[0]),
        create(:subcompany, verticals: [verticals[0]], company: companies[1]),
        create(:subcompany, verticals: [verticals[1]], company: companies[2])
      ]
    end

    it do
      subject.up

      expect(categories[0].reload.visible_to_customer).not_to eq true
      expect(categories[1].reload.visible_to_customer).not_to eq false
      expect(categories[2].reload.visible_to_customer).to eq true
      expect(categories[3].reload.visible_to_customer).not_to eq true
      expect(categories[4].reload.visible_to_customer).not_to eq true
      expect(categories[5].reload.visible_to_customer).not_to eq true
      expect(categories[1].plans).to be_empty
      expect(categories[5].plans).to be_empty

      expect(categories[6].plans.count).to eq 2
      umbrella1_plans_names = categories[6].plans.map(&:name)
      expect(umbrella1_plans_names).to include "#{categories[6].name} #{companies[0].name}"
      expect(umbrella1_plans_names).to include "#{categories[6].name} #{companies[1].name}"

      expect(categories[7].plans.count).to eq 2
      umbrella2_plans_names = categories[7].plans.map(&:name)
      expect(umbrella2_plans_names).to include "#{categories[7].name} #{companies[0].name}"
      expect(umbrella2_plans_names).to include "#{categories[7].name} #{companies[1].name}"

      expect(categories[8].plans.count).to eq 1
      expect(categories[8].plans.first.name).to eq "#{categories[8].name} #{companies[2].name}"
    end
  end

  describe "#down" do
    let!(:category) { create(:category, :active, :umbrella, metadata: { visible_to_customer: true }) }
    let!(:plan) { create(:plan, category: category) }

    it do
      subject.down
      expect(category.reload.visible_to_customer).not_to eq true
      expect(category.plans).to be_blank
    end
  end
end
