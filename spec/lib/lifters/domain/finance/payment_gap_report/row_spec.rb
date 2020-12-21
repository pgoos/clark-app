# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentGapReport::Row do
  subject { described_class.new(attributes) }

  let(:attributes) do
    {
      product_id: "1",
      opportunity_completed_at: 1.day.ago,
      insurance_started_at: 1.day.ago,
      customer: "Joe Doe",
      managed_by: "Joe Doe 2",
      insurance_number: "12345",
      insurance_document_uploaded_at: 1.day.ago,
      sales_cancel_at: 1.day.ago,
      acquisition_commission_payouts_count: "1",
      total_sales_fee: "2",
      received_sales_fee: "3",
      canceled_sales_fee: "4",
      sales_fee_gap: "5",
      total_management_fee: "6",
      received_management_fee: "7",
      canceled_management_fee: "8",
      management_fee_gap: "9"
    }
  end

  it "initializes fields" do
    attributes.each do |name, value|
      expect(subject.send(name)).to eq value
    end
  end
end
