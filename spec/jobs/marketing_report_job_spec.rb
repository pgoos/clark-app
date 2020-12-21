# frozen_string_literal: true

require "rails_helper"

RSpec.describe MarketingReportJob, type: :job do
  describe ".perform" do
    let(:admin_email) { "admin@example.com" }
    let(:csv) { "csv" }

    before do
      allow_any_instance_of(Domain::Reports::Marketing::IncentivePayoutCsv)
        .to receive(:generate_csv).and_return(csv)
    end

    it "should not generate the report" do
      expect(Domain::Reports::Marketing::IncentivePayoutCsv).not_to receive(:generate_csv)

      subject.perform("IncentivePayout", admin_email)
    end

    it "should send the ReportMailer mail", skip: true do
      params = {to: admin_email, subject: "Incentive Payout Report (DE)", csv: csv, csv_name: "incentive_payout.csv"}
      expect(ReportMailer).to receive(:csv_report).with(params).and_call_original
      subject.perform("IncentivePayout", admin_email)
    end

    context "run with force param true" do
      it "should send the report" do
        params = {to: admin_email, subject: "Incentive Payout Report (DE)", csv: csv, csv_name: "incentive_payout.csv"}
        expect(ReportMailer).to receive(:csv_report).with(params).and_call_original
        subject.perform("IncentivePayout", admin_email, true)
      end
    end

    context "Incentive Payout report" do
      let(:csv_report) { double :mail, deliver_now: nil }

      before do
        allow(ReportMailer).to receive(:csv_report).and_return(csv_report)
      end

      it "should include DE in the email subject" do
        expect(ReportMailer).to receive(:csv_report).with(hash_including(subject: /DE/))
        subject.perform("IncentivePayout", admin_email, true)
      end

      context "Austria context" do
        before do
          allow(Internationalization).to receive(:locale).and_return(:at)
        end

        it "should include AT in the email subject" do
          expect(ReportMailer).to receive(:csv_report).with(hash_including(subject: /AT/))
          subject.perform("IncentivePayout", admin_email, true)
        end
      end
    end
  end
end
