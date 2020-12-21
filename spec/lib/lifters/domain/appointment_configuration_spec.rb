# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Admins::AppointmentConfiguration, :integration do
  let(:subject) { described_class.new }

  describe "#categories" do
    let!(:regular) { create(:category, :regular, name: "AA") }

    context "when diffrent types of categories exists" do
      it "returns only active regular and umbrella categories" do
        umbrella = create(:category, :umbrella)
        combo = create(:category, :combo)
        inactive_category = create(:category, :inactive)

        expect(subject.categories).to include(regular)
        expect(subject.categories).to include(umbrella)
        expect(subject.categories).not_to include(combo)
        expect(subject.categories).not_to include(inactive_category)
      end

      it "returns list in sorted by name order" do
        category_b = create(:category, :regular, name: "BB")
        category_z = create(:category, :regular, name: "ZZ")

        expect(subject.categories.pluck(:id)).to eq(
          [
            regular.id,
            category_b.id,
            category_z.id
          ]
        )
      end
    end
  end

  describe "#sales_campaigns" do
    context "when sales_campaigns exists" do
      let!(:sales_campaign_z) { create(:sales_campaign, name: "ZZ") }
      let!(:sales_campaign_a) { create(:sales_campaign, name: "AA") }
      let!(:sales_campaign_b) { create(:sales_campaign, name: "BB") }
      let!(:inactive_sales_campaign) { create(:sales_campaign, active: false) }

      it "return active sales_campaigns" do
        expect(subject.sales_campaigns).to eq([sales_campaign_a, sales_campaign_b, sales_campaign_z])
      end
    end
  end

  describe "#source_descriptions" do
    context "when source_description exists" do
      let!(:source_description_z) { create(:opportunity_source_description, description: "ZZ") }
      let!(:source_description_a) { create(:opportunity_source_description,description: "AA") }
      let!(:source_description_b) { create(:opportunity_source_description, description: "BB") }

      it "returns source_description" do
        expect(subject.source_descriptions).to eq([source_description_a, source_description_b, source_description_z])
      end
    end
  end
end
