# frozen_string_literal: true

require "rails_helper"

describe "rake incentive_payout_report:send_email", type: :task do
  let(:csv) { double :csv }
  let(:repository) {
    object_double Domain::Reports::Marketing::IncentivePayoutCsv.new,
                  generate_csv: csv,
                  filename: "Filename"
  }
  let(:report) { double :report, deliver_now: true }

  before do
    allow(Domain::Reports::Marketing::IncentivePayoutCsv).to receive(:new).and_return repository
    allow(ReportMailer).to receive(:csv_report).and_return report
  end

  it "sends the IncentivePayout Report email" do
    expect(report).to receive(:deliver_now)
    task.invoke
  end
end
