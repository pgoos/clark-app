# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentGapReport::GenerateAndSendJob, type: :job do
  let(:from) { 1.year.ago }
  let(:to) { 1.day.ago }
  let(:receiver) { "fake_email@clark.de" }
  let(:service_double) { double(:service_double) }

  it "creates and calls service object" do
    expect(Domain::Finance::PaymentGapReport::Generator).to receive(:email_with_csv).and_return(service_double)
    expect(service_double).to receive(:call)
    subject.perform(from, to, receiver)
  end
end
