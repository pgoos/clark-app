# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportMailer, :integration, type: :mailer do
  let(:email) { "test@test.com" }

  describe "#csv_report" do
    let(:mail) {
      ReportMailer.csv_report(
        to: email,
        subject: "Incentive Payout Report",
        csv_name: "incentive_payout.csv",
        csv: "some csv content"
      )
    }

    include_examples "checks mail rendering"

    it "tracks document" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    end
  end
end
