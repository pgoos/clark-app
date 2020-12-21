# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/seed"
require "composites/offers/constituents/manual_creation/entities/plan"

RSpec.describe Offers::Constituents::ManualCreation::Seed, :integration do
  subject(:seeds) { described_class.new }

  it "includes Utils::Seeder in included modules" do
    expect(seeds).to be_kind_of Utils::Seeder
  end

  describe "#create_single_option_offer" do
    let(:customer) { create(:customer) }

    it "creates offer with on option" do
      option = seeds.create_single_option_offer(customer.id)
      expect(option.product.plan.ident).to eq described_class::PLAN_IDENT
      expect(option.offer.mandate_id).to eq customer.id
    end
  end

  describe "#find_or_create_plan" do
    it "creates plans" do
      plan = nil
      expect { plan = seeds.find_or_create_plan }.to change(Plan, :count).by(1)
      expect(plan).to be_a Offers::Constituents::ManualCreation::Entities::Plan
      expect(plan.ident).to eq described_class::PLAN_IDENT

      plan = Plan.find_by(ident: plan.ident)
      expect(plan.premium_price_cents).to eq 2000
      expect(plan.premium_price_currency).to eq "EUR"
      expect(plan.premium_period).to eq "month"
      expect(plan.state).to eq "active"

      expect { seeds.find_or_create_plan }.not_to change(Plan, :count)
    end

    context "plan with ident #{described_class::PLAN_IDENT} already exist" do
      let(:plan) { create(:plan, ident: described_class::PLAN_IDENT, premium_price_cents: 1000) }

      it "updates plan" do
        seeds.find_or_create_plan
        plan = Plan.find_by(ident: described_class::PLAN_IDENT)
        expect(plan.premium_price_cents).to eq 2000
      end
    end
  end
end
