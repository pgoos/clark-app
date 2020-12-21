# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Marketing::OpportunitiesWoAppointmentCsv do
  translation_key = "admin.marketing.reports.opportunities_wo_appointment"
  csv_data_row = %w[
    opportunity_id first_name last_name http://test.host/de/admin/mandates/mandate_link/opportunities/opportunity_link
    http://test.host/de/admin/mandates/mandate_link state phone_number category_name
  ]
  expected_csv = CSV.generate do |csv|
    csv << described_class.new.repository.class.fields_order.map { |n| I18n.t("#{translation_key}.#{n}") }
    csv << csv_data_row
    csv << csv_data_row
  end

  it_behaves_like "a csv report", translation_key, nil, expected_csv
end
