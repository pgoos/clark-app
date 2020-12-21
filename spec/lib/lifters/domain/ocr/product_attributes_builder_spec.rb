# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OCR::ProductAttributesBuilder do
  describe "#build" do
    let(:category) { create(:category) }
    let(:plan_ident) { "ident" }
    let(:insurance_number) { "number" }

    let(:mandate) { create(:mandate) }
    let(:subcompany) { create(:subcompany) }

    let(:inquiry) { create(:inquiry, subcompany: subcompany, mandate: mandate) }
    let(:inquiry_category) { create(:inquiry_category, inquiry: inquiry, category: category) }
    let!(:plan) { create(:plan, ident: plan_ident, subcompany: subcompany, category: category) }

    let(:payload) do
      instance_double(OCR::ContractDataMapper,
                      contract_start: "2018-01-01".to_date, contract_end: "2019-10-20".to_date,
                      premium_period: "vierteljährlich", premium_price: "20.40",
                      premium_state: "normaler Beitrag", plan_ident: plan_ident,
                      mandate_id: mandate.id.to_s,
                      insurance_number: insurance_number)
    end

    context "with a valid payload" do
      it "returns the correct product attributes" do
        builder = described_class.new(payload, inquiry_category)
        expect(builder.valid_product?).to eq true

        attributes = builder.build
        expect(Product.new(attributes)).to be_valid
        expect(attributes[:plan_id]).to eq plan.id
        expect(attributes[:number]).to eq insurance_number
        expect(attributes[:inquiry_id]).to eq inquiry_category.inquiry_id
        expect(attributes[:renewal_period]).to be_nil
        expect(attributes[:annual_maturity]).to be_nil
        expect(attributes[:premium_period]).to eq :quarter
        expect(attributes[:premium_state]).to eq :premium
        expect(attributes[:mandate_id]).to eq mandate.id.to_s
      end

      context "with property categories" do
        let(:category) { create(:category, :suhk) }

        it "sets the correct renewal_period and the annual_maturity" do
          builder = described_class.new(payload, inquiry_category)
          attributes = builder.build

          expect(attributes[:renewal_period]).to eq 12
          expect(attributes[:annual_maturity]).to eq(day: 20, month: 10)
        end
      end

      context "with transferable plans" do
        let(:subcompany) { create(:subcompany, pools: ["Pool 1"]) }

        it "sets the empty portfolio_comission_price" do
          builder = described_class.new(payload, inquiry_category)
          expect(builder.valid_product?).to eq true

          attributes = builder.build
          expect(attributes[:portfolio_commission_price]).to eq 0
        end
      end
    end

    context "with invalid products" do
      context "without a plan" do
        before { plan.update!(ident: "other_ident") }

        it "returns the correct errors" do
          builder = described_class.new(payload, inquiry_category)
          expect(builder.valid_product?).to eq false
          errors = builder.product_errors
          expect(errors).to be_present

          message = "#{I18n.t('attributes.plan')} #{I18n.t('errors.messages.required')}"
          expect(errors.first).to eq message
        end
      end

      context "with a wrong premium_period" do
        before { allow(payload).to receive(:premium_period).and_return("invalid") }

        it "returns the correct errors" do
          builder = described_class.new(payload, inquiry_category)
          expect(builder.valid_product?).to eq false
          errors = builder.product_errors
          expect(errors).to be_present

          message = "#{I18n.t('activerecord.attributes.product.premium_period')} #{I18n.t('errors.messages.inclusion')}"
          expect(errors.first).to eq message
        end
      end
    end
  end
end
