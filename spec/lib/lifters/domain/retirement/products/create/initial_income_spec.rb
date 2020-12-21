# frozen_string_literal: true

require "rails_helper"

describe Domain::Retirement::Products::Create::InitialIncome do
  describe "#call" do
    subject { described_class.new(mandate) }

    let(:mandate) { create(:mandate) }

    before do
      create(:plan, ident: "brdb0998", subcompany: create(:subcompany))
      create(:category, ident: "84a5fba0")
    end

    context "when no state products created yet" do
      before { @retirement_product = subject.call }

      it "creates product in state 'customer_provided'" do
        expect(@retirement_product.product).to be_customer_provided
      end

      it "creates retirement-product in state 'details_available'" do
        expect(@retirement_product).to be_details_available
      end

      it "retirement-product#forecast is initial" do
        expect(@retirement_product.forecast).to eq "initial"
      end

      it "product and retirement product belongs to the mandate" do
        expect(@retirement_product.product.mandate).to eq mandate
      end
    end

    context "when already have state product" do
      let(:product) { create(:product, mandate: mandate) }
      let!(:state_product) { create(:retirement_state_product, product: product) }

      before { @retirement_product = subject.call }

      it "doesn't create a new product" do
        expect(mandate.products.last).to eq product
      end

      it "doesn't create a new retirement product" do
        expect(mandate.retirement_products.last).to eq state_product
      end
    end
  end
end
