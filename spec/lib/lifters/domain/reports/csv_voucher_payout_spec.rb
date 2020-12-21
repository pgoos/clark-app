# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::CsvVoucherPayout do
  subject { described_class.new(admin: admin) }

  let(:admin) { create(:admin) }

  it_behaves_like "a csv report", "admin.vouchers.payout_report"

  describe "#transform!" do
    let(:report_fields) { %w[id birthdate] }
    let(:report_values) { %w[value1 1979-04-22\ 23:00:00] }

    let(:report_data) do
      [
        Hash[report_fields.zip(report_values)]
      ]
    end
    let(:repository) do
      repo = double(:repository)
      allow(repo.class).to receive(:fields_order).and_return(report_fields)
      allow(repo).to receive(:all).and_return(report_data)
      repo
    end

    let(:report_encoding) { nil }

    it "transforms birthdate timestamp to date" do
      subject.repository = repository
      subject.encoding = report_encoding
      last_column = subject.generate_csv.split("\n").last
      expect(last_column).to eq("value1,23.04.1979")
    end
  end
end
