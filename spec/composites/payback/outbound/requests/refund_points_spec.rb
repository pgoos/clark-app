# frozen_string_literal: true

require "rails_helper"
require "composites/payback/entities/payback_transaction"
require "composites/payback/outbound/requests/refund_points"
require "./spec/composites/payback/outbound/requests/response_methods"

RSpec.describe Payback::Outbound::Requests::RefundPoints do
  let(:request) { described_class.new(payback_transaction, payback_number) }

  let(:payback_transaction) do
    build(
      :payback_transaction_entity,
      :refund,
      :with_inquiry_category,
      receipt_no: refund_receipt_no,
      info: {
        "original_transaction_date" => (DateTime.now - 5.days).to_s
      }
    )
  end

  let(:payback_number) { Luhn.generate(13, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX) }
  let(:refund_receipt_no) { "1-1-I_REFUND" }

  let(:excepted_item_details) do
    {
      points_amount: payback_transaction.points_amount,
      article_number: payback_transaction.subject_id,
      partner_product_category_code: payback_transaction.category_id,
      partner_product_category_name: payback_transaction.generated_category_name,
      single_turnover_amount: described_class::DEFAULT_FLOAT_AMOUNT,
      quantity: described_class::DEFAULT_QUANTITY,
      total_turnover_amount: described_class::DEFAULT_FLOAT_AMOUNT,
      total_rewardable_amount: described_class::DEFAULT_FLOAT_AMOUNT,
      vat_amount: described_class::DEFAULT_VAT_AMOUNT,
      vat_rate: described_class::DEFAULT_VAT_AMOUNT
    }
  end

  let(:excepted_message) do
    {
      collect_event_data: {
        effective_date: payback_transaction.effective_date.iso8601,
        receipt_number: refund_receipt_no,
        communication_channel: Payback::Outbound::Client::COMMUNICATION_CHANNEL
      },
      transactions: [
        {
          transaction_type: described_class::TRANSACTION_TYPE,
          total_points: { loyalty_amount: payback_transaction.points_amount },
          points_blocked_until: payback_transaction.locked_until.iso8601,
          vat_rate: described_class::DEFAULT_VAT_AMOUNT
        }
      ],
      refund_legal_value: { legal_amount: described_class::DEFAULT_FLOAT_AMOUNT },
      refund_vat_legal_value: { legal_amount: described_class::DEFAULT_VAT_AMOUNT },
      reference_receipt_number: payback_transaction.original_refunded_receipt_no,
      refund_item_details: excepted_item_details
    }
  end

  include_examples "response_methods"

  describe "#call" do
    it "should call build_message method to build the message for request" do
      expect(request).to receive(:build_message)

      request.call
    end

    it "should call the method to add collect_event_data" do
      expect(request).to receive(:build_collect_event_data).and_call_original

      request.call
    end

    it "should call the method to add transaction_data" do
      expect(request).to receive(:build_transaction_data).and_call_original

      request.call
    end

    it "should call the method to add refund data" do
      expect(request).to receive(:build_refund_data).and_call_original

      request.call
    end

    it "should execute call method on client" do
      expect(request.instance_variable_get(:@client)).to receive(:call) \
        .with(:refund_purchase_event, message: excepted_message)

      request.call
    end

    context "when subject of transaction is deleted" do
      let(:subject_category_id) { 9999 }
      let(:subject_category_name) { "test_cat" }
      let(:subject_company_name) { "test_company_name" }

      before do
        allow(payback_transaction).to receive(:category_id).and_return(nil)
        allow(payback_transaction).to receive(:category_name).and_return(nil)
        allow(payback_transaction).to receive(:company_name).and_return(nil)

        payback_transaction.info["category_id"] = subject_category_id
        payback_transaction.info["category_name"] = subject_category_name
        payback_transaction.info["company_name"] = subject_company_name
      end

      it "builds item details using subject related data from info column" do
        excepted_item_details[:partner_product_category_code] = subject_category_id
        excepted_item_details[:partner_product_category_name] =
          Payback::Generators::CategoryName.call(subject_category_name, subject_company_name)

        expect(request.instance_variable_get(:@client)).to receive(:call) \
          .with(:refund_purchase_event, message: excepted_message)

        request.call
      end
    end
  end

  describe "#attributes_to_be_updated" do
    before do
      request.call
    end

    it "should return hash containing locked until and points amount with the values from response" do
      points_amount = request.points_amount_on_response

      expect(request.attributes_to_be_updated).to eq(points_amount: points_amount)
    end
  end
end
