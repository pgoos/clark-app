# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentGapReport::Formatters::CSV do
  subject { described_class.new(data) }

  let(:data) { [Domain::Finance::PaymentGapReport::Row.new(attributes)] }
  let(:attributes) do
    {
      product_id: "product_id_fake_value",
      opportunity_completed_at: "2019-08-28 14:28:10 +0200",
      insurance_started_at: "2019-08-28 14:28:10 +0200",
      customer: "customer_fake_value",
      subcompany_name: "subcompany_name_fake_value",
      managed_by: "managed_by_fake_value",
      insurance_number: "insurance_number_fake_value",
      insurance_document_uploaded_at: "2019-08-28 14:28:10 +0200",
      sales_cancel_at: "2019-08-28 14:28:10 +0200",
      acquisition_commission_payouts_count: "1",
      total_sales_fee: "200",
      received_sales_fee: "300",
      canceled_sales_fee: "400",
      sales_fee_gap: "500",
      total_management_fee: "600",
      received_management_fee: "700",
      canceled_management_fee: "800",
      management_fee_gap: "900"
    }
  end

  context "#generate!" do
    it "generates csv" do
      path_name = subject.generate!

      csv = CSV.read(path_name)
      expect(csv.first).to eq(
        [
          "Product_id",
          "opportunity_completed_date",
          "Versicherungsbeginn",
          "Kunde",
          "Gesellschaft",
          "Verwaltet über",
          "Versicherungsnummer",
          "Document_type date created at",
          "sales_cancel_date",
          "acquisition_commission_payouts_count",
          "total_sales_fee",
          "received_sales_fee",
          "canceled_sales_fee",
          "sales_fee_gap",
          "total_management_fee",
          "received_management_fee",
          "canceled_management_fee",
          "management_fee_gap"
        ]
      )
      expect(csv.last).to eq(
        [
          "product_id_fake_value",
          "2019-08-28 14:28:10 +0200",
          "2019-08-28 14:28:10 +0200",
          "customer_fake_value",
          "subcompany_name_fake_value",
          "managed_by_fake_value",
          "insurance_number_fake_value",
          "2019-08-28 14:28:10 +0200",
          "2019-08-28 14:28:10 +0200",
          "1",
          "2.0",
          "3.0",
          "4.0",
          "5.0",
          "6.0",
          "7.0",
          "8.0",
          "9.0"
        ]
      )
    end
  end
end
