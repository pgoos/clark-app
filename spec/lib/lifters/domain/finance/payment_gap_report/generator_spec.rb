# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentGapReport::Generator do
  context ".email_with_csv" do
    subject { described_class.email_with_csv(yesterday, now, "test@clark.de") }

    let(:yesterday) { 1.day.ago }
    let(:now) { Time.zone.now }
    let(:receiver) { "test@clark.de" }

    it "initializes service with proper params" do
      expect(Domain::Finance::PaymentGapReport::Base).to receive(:new).with(
        from: yesterday,
        to: now,
        receiver: receiver,
        formatter: Domain::Finance::PaymentGapReport::Formatters::CSV
      )
      subject
    end
  end
end
