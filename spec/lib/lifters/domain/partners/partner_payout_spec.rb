# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Partners::PartnerPayout do
  let(:partner_ident) { "partner" }
  let(:mandate) { create(:mandate, :accepted) }
  let(:partner) { create(:partner, ident: partner_ident) }
  let!(:partner_payout_rule) {
    create(
      :partner_payout_rule,
      partner: partner,
      mandate_created_from: mandate.created_at - 1.day,
      mandate_created_to: mandate.created_at + 1.month
    )
  }
  let(:subject) { described_class.new(mandate, partner_ident) }

  describe "#payout_amount" do
    context "payout rules with no required_products_count" do
      it "returns 0 if mandate is not accepted" do
        mandate.state = :created
        expect(subject.payout_amount).to eq(0)
      end

      it "returns the payout amount of the payout rule that matches the mandate creation date if exists" do
        expect(subject.payout_amount).to eq(partner_payout_rule.payout_amount)
      end

      it "returns the payout amount of the most recent payout rule if multiple match the mandate" do
        payout_amount = "1234"
        later_payout_rule =
          create(:partner_payout_rule,
                 partner: partner,
                 mandate_created_from: (mandate.created_at - 2.days),
                 mandate_created_to: mandate.created_at + 1.month,
                 payout_amount: payout_amount)
        expect(subject.payout_amount).to eq(later_payout_rule.payout_amount)
      end
    end

    context "payout rules with required_products_count" do
      before do
        partner_payout_rule.update(products_count: 1)
      end

      context "mandate has no products" do
        it "returns 0 if mandate matches the payout rule interval but not the products" do
          expect(subject.payout_amount).to eq(0)
        end
      end

      context "mandate has a product" do
        let!(:product) { create(:product, :phv, :details_available, mandate: mandate) }

        it "returns the payout amount specified in the rule if mandate matches the products count" do
          expect(subject.payout_amount).to eq(partner_payout_rule.payout_amount)
        end

        it "returns 0 if the product is older than 1 year from the mandate creation date" do
          product.update(created_at: mandate.created_at + 13.months)
          expect(subject.payout_amount).to eq(0)
        end

        it "returns 0 if the product is a non payable category" do
          described_class::NON_PAYABLE_PRODUCT_CATEGORY_IDENTS.each do |category_ident|
            product.plan.category = create(:category, ident: category_ident)
            product.plan.save!
            expect(subject.payout_amount).to eq(0)
          end
        end

        it "returns 0 if the product is not in a payable state (terminated)" do
          product.update!(state: :terminated)
          expect(subject.payout_amount).to eq(0)
        end
      end
    end
  end
end
