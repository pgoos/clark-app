# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Marketing::VoucherCustomerReport do
  it_behaves_like "a csv report", "admin.marketing.reports.voucher_customer"

  describe "after_generate" do
    it "runs the ReportMailer block" do
      expect(ReportMailer).to receive(:csv_report).and_call_original
      subject.generate_csv
    end
  end
end
