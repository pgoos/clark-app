# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Recommendations::Constituents::Overview::Repositories::OfferRepository, :integration do
  let(:offer) { create(:offer) }
  let!(:offer_option) { create(:offer_option, offer: offer) }

  describe ".find_attributes" do
    context "when offer_id is passed in" do
      it "returns offer attributes" do
        attributes = described_class.new.find_attributes(offer.id)
        expected_attributes = {
          id: offer.id,
          cheapest_option: {
            payment: {
              type: "FormOfPayment",
              value: offer_option.product.premium_period
            },
            price: {
              currency: "EUR",
              value: offer_option.product.premium_price_cents
            }
          }
        }

        expect(attributes).to eq(expected_attributes)
      end
    end
  end
end
