# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Partners::MamProductLoyaltyBooking do
  let(:mandate) { create(:mandate, :mam) }
  let(:product) { create(:product, mandate: mandate) }
  let(:booking_code) { "code" }
  let(:miles_to_book) { 50 }
  let(:subject) { described_class.new(product, miles_to_book, booking_code) }

  context "initialize" do
    it "assigns the attr reader values" do
      instance_object = subject
      expect(instance_object.product).to eq(product)
      expect(instance_object.miles_to_book).to eq(miles_to_book)
      expect(instance_object.mam_property_code).to eq(booking_code)
    end
  end

  context "#create_loyalty_booking!" do
    it "creates a loyalty booking from the attributes extracted from the instance objects" do
      expect { subject.create_loyalty_booking! }.to change(LoyaltyBooking, :count).by(1)
    end
  end

  context "#member_alias" do
    it "returns the instance product's mandate mam member alias" do
      expect(subject.member_alias).to eq(mandate.mam_member_alias)
    end
  end

  context "#action" do
    it "returns capital c for a fixed action value for mam" do
      expect(subject.action).to eq("C")
    end
  end

  context "#additional_partner_data" do
    it "returns a hash with the booking code" do
      expect(subject.additional_partner_data).to eq(mam_property_code: booking_code)
    end
  end

  context "#product_id" do
    it "returns the instance product id" do
      expect(subject.product_id).to eq(product.id)
    end
  end
end
