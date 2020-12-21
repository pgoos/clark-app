# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::De::CockpitTotals do
  subject { described_class }

  let(:products) do
    [
      build_stubbed(:product, premium_price: 100, premium_period: "month"),
      build_stubbed(:product, premium_price: 216, premium_period: "year"),
      build_stubbed(:product, premium_price: 500, premium_period: "once")
    ]
  end

  include_examples "shared cockpit totals behaviour"
end
