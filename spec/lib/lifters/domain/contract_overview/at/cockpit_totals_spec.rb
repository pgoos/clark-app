# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::At::CockpitTotals do
  subject { described_class }

  include_examples "shared cockpit totals behaviour"

  describe "#products_monthly_total" do
    it "does not exclude products which contract has ended but renewal period is present" do
      products = [
        build_stubbed(:product, premium_price: 100, premium_period: "month", contract_ended_at: Time.zone.tomorrow),
        build_stubbed(
          :product, premium_price: 216, premium_period: "year", contract_ended_at: 1.day.ago, renewal_period: 1
        )
      ]
      expect(subject.products_monthly(products)).to be_a Money
      expect(subject.products_monthly(products).to_i).to eq 118
    end
  end
end
