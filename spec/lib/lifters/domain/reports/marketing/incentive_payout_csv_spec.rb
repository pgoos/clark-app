# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Marketing::IncentivePayoutCsv do
  it_behaves_like "a csv report", "admin.marketing.reports.incentive_payout", "UTF-8"
end
