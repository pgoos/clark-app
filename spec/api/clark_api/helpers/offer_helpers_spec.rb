# frozen_string_literal: false

require "rails_helper"

RSpec.describe ClarkAPI::Helpers::OfferHelpers do
  let(:clazz) { Class.new { extend ClarkAPI::Helpers::OfferHelpers } }

  describe "#note_placeholder_replace" do
    let(:mandate) { create(:mandate) }
    let(:offer) { create(:offer, mandate: mandate) }
    let(:company1) { create(:company, name: "Recommended EuroInsurance") }
    let(:company2) { create(:company, name: "Some other company name LTD") }
    let!(:offer_product1) { create(:product, mandate: mandate, company: company1) }
    let!(:offer_product2) { create(:product, mandate: mandate, company: company2) }
    let!(:offer_option1) { create(:offer_option, product: offer_product1, recommended: true, offer: offer) }
    let!(:offer_option2) { create(:offer_option, product: offer_product2, offer: offer) }

    context "when note_to_customer contain some placeholder to replace" do
      let(:note) { "Hello Customer, we recommend you {recommended_company_name}" }

      it "should replace placeholder with correct value" do
        result = clazz.note_placeholder_replace(offer, note)

        expect(result).to eq("Hello Customer, we recommend you Recommended EuroInsurance")
      end
    end

    context "when note_to_customer doesn\'t contain some placeholder to replace" do
      let(:note) { "Hello Customer, what\'s up?" }

      it "should not replace anything" do
        result = clazz.note_placeholder_replace(offer, note)

        expect(result).to eq("Hello Customer, what\'s up?")
      end
    end
  end
end
