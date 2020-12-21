# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/repositories/plan_repository"
require "composites/utils/repository/errors"

RSpec.describe Offers::Constituents::ManualCreation::Repositories::PlanRepository do
  subject { described_class.new }

  describe "#active_plans_for_category", :integration do
    let!(:plans) do
      [
        create(:plan, :activated, :with_stubbed_coverages),
        create(:plan, :deactivated),
        create(:plan, :activated)
      ]
    end

    it "passes scenario" do
      # valid category ident provided
      result = subject.active_plans_for_category(plans[0].category.ident)
      expect(result.size).to eq 1
      plan = result.first
      expect(plan).to be_a(Offers::Constituents::ManualCreation::Entities::Plan)
      expect(plan.name).to eq plans[0].name
      expect(plan.ident).to eq plans[0].ident
      expect(plan.company_name).to eq plans[0].company_name

      # invalid category ident provided
      expect {
        subject.active_plans_for_category("non-existing-ident")
      }.to raise_error(Utils::Repository::Errors::Error)
    end
  end

  describe "#plan_with_details", :integration do
    let(:document1) { create(:document) }
    let(:document2) { create(:document) }

    let(:parent_plan) { create(:parent_plan, documents: [document1, document2]) }
    let!(:plan) { create(:plan, :activated, :with_stubbed_coverages, parent_plan: parent_plan) }

    it "returns plan with details" do
      # valid plans ident provided
      result = subject.plan_with_details(plan.ident)
      expect(result).to be_a(Offers::Constituents::ManualCreation::Entities::PlanWithDetails)
      expect(result.name).to eq plan.name
      expect(result.ident).to eq plan.ident
      expect(result.coverages.size).to eq plan.coverages.size
      expect(result.documents.size).to eq plan.documents.size
      expect(result.documents.first).to be_a(Offers::Constituents::ManualCreation::Entities::Document)

      # invalid plans ident provided
      expect {
        subject.plan_with_details("fake-ident")
      }.to raise_error(Utils::Repository::Errors::Error)
    end
  end
end
