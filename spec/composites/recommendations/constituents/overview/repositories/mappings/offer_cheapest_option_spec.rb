# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommendations::Constituents::Overview::Repositories::Mappings::OfferCheapestOption, :integration do
  describe ".entity_value" do
    let(:offer) { create(:offer) }
    let(:mapper) { described_class }

    context "when cheap product exists for Offer" do
      let(:offer_option) { create(:offer_option, offer: offer) }

      it "returns product details" do
        expected_response = {
          payment: {
            type: "FormOfPayment",
            value: offer_option.product.premium_period
          },
          price: {
            currency: "EUR",
            value: offer_option.product.premium_price_cents
          }
        }

        expect(mapper.entity_value(offer_option.offer.id)).to eq(expected_response)
      end
    end

    context "when products does not exists for Offer" do
      it "returns nil template" do
        expected_response = {
          payment: {
            type: nil,
            value: nil
          },
          price: {
            currency: nil,
            value: nil
          }
        }

        expect(mapper.entity_value(offer.id)).to eq(expected_response)
      end
    end
  end
end
