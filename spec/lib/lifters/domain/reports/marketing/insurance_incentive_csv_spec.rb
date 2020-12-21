# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Marketing::InsuranceIncentiveCsv do
  it_behaves_like "a csv report", "admin.marketing.reports.insurance_incentive"
end
