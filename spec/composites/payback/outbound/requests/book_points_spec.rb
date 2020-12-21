# frozen_string_literal: true

require "rails_helper"
require "composites/payback/entities/payback_transaction"
require "composites/payback/outbound/requests/book_points"
require "./spec/composites/payback/outbound/requests/response_methods"

RSpec.describe Payback::Outbound::Requests::BookPoints do
  let(:request) { described_class.new(payback_transaction, payback_number) }

  let(:payback_transaction) do
    build(
      :payback_transaction_entity,
      :book,
      :with_inquiry_category,
      info: {
        "effective_date": Faker::Time.between(from: DateTime.now - 15.days, to: DateTime.now),
        "initial_points_amount": Payback::Entities::PaybackTransaction::DEFAULT_POINTS_AMOUNT
      }
    )
  end

  let(:payback_number) { Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX) }

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

    it "should execute call method on client" do
      expect(request.instance_variable_get(:@client)).to receive(:call) \
        .with(:process_purchase_event, hash_including(:message))

      request.call
    end
  end

  describe "#attributes_to_be_refreshed" do
    before do
      request.call
    end

    it "should return hash containing locked until and points amount with the values from response" do
      points_amount = request.points_amount_on_response

      expect(request.attributes_to_be_updated).to eq(points_amount: points_amount)
    end
  end
end
