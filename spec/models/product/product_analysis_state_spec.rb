# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  let(:mandate_customer) { create(:mandate, customer_state: "mandate_customer") }
  let(:offer) { build :offer, :in_creation, mandate: mandate_customer }
  let(:product) { build(:product, inquiry: build_stubbed(:inquiry), mandate: mandate_customer) }
  let!(:offer_option) { build(:offer_option, product: product, offer: offer) }

  context "offered product" do
    it "setup analysis_state to 'details_complete' for offered product" do
      product.state = "offered"
      expect(product.save).to be_truthy
      expect(product.analysis_state).to eq("details_complete")
    end

    it "does not setup analysis_state for offered product and mandate with empty 'customer_state'" do
      product.state = "offered"
      mandate_customer.update_attributes(customer_state: nil)
      expect(product.save).to be_truthy
      expect(product.analysis_state).to be_nil
    end
  end

  context "non offered product" do
    it "setup analysis_state to 'details_missing' for mandate with populated 'customer_state'" do
      expect(product.save).to be_truthy
      expect(product.analysis_state).to eq("details_missing")
    end

    it "does not setup analysis_state to 'details_missing' for mandate with empty 'customer_state'" do
      mandate_customer.update_attributes(customer_state: nil)
      expect(product.save).to be_truthy
      expect(product.analysis_state).to be_nil
    end
  end
end
