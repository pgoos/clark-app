# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Ops::RetrieveActiveLowMarginOffers do
  it_behaves_like "a csv report", "admin.offers.reports.active_low_margin_offers"
end
