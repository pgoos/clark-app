# frozen_string_literal: true

require "rails_helper"
require "composites/payback/factories/request"
require "composites/payback/outbound/requests/book_points"
require "composites/payback/entities/customer"

RSpec.describe Payback::Factories::Request do
  let(:payback_number) { Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX) }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  describe ".build" do
    context "when transaction_type is book" do
      it "should instantiate BookPoints request" do
        allow(Payback::Outbound::Requests::BookPoints).to receive(:new).and_return(nil)

        expect(Payback::Outbound::Requests::BookPoints).to receive(:new)
        described_class.build(payback_transaction, payback_number)
      end
    end
  end
end
