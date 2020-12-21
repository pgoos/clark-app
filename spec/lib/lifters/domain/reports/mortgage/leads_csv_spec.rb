# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Mortgage::LeadsCsv do
  translation_key = "admin.mortgage.reports.leads"
  csv_data_row = %w[
    mandate_id
    first_name
    last_name
    mandate_created_at
    phone_number
    age
    grossincome
    demand_estate_answer
    demand_financing_answer
    answer_date
  ]

  expected_csv = CSV.generate do |csv|
    csv << described_class.new.repository.class.fields_order.map { |field| I18n.t("#{translation_key}.#{field}") }
    csv << csv_data_row
    csv << csv_data_row
  end

  it_behaves_like "a csv report", translation_key, nil, expected_csv
end
