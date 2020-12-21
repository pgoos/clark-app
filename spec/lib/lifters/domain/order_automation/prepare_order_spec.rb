# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OrderAutomation::PrepareOrder, :integration do
  let(:mandate) { build_stubbed(:mandate, iban: "iban") }
  let(:subcompany) do
    build_stubbed(
      :subcompany, contact_type: "quality_pool", quality_pool_broker_nr: "number", uci: "1235", order_email: "test@test123.com"
    )
  end

  let(:product) { build :product, attributes }
  let(:admin) { build :admin }
  let(:attributes) do
    {
      state: :order_pending, contract_started_at: 1.day.from_now, contract_ended_at: 4.days.from_now,
      offer_option: build(:offer_option, offer: build(:offer, opportunity: build(:opportunity)))
    }
  end

  let(:subject) { Domain::OrderAutomation::PrepareOrder.new(product, admin) }

  before do
    allow(product).to receive(:mandate).and_return(mandate)
    allow(mandate).to receive(:user).and_return(build_stubbed(:user))
    allow(product).to receive(:plan).and_return(
      build_stubbed(:plan, :with_insurance_tax)
    )
    allow(product).to receive(:subcompany).and_return(subcompany)
    allow(product).to receive(:company).and_return(build_stubbed(:company))
    allow(product).to receive(:category).and_return(build_stubbed(:category))
    allow(product).to receive(:suhk?).and_return subcompany
  end

  context "product state = order_pending" do
    context "product has valid contract start date" do
      context "product has valid contract end date" do
        context "subcompany has value for uci" do
          before { subject.call }

          it "links cover note to product" do
            expect(product.documents.where(document_type: DocumentType.deckungsnote)).not_to be_blank
          end

          it "links advisory documentation to product" do
            expect(product.documents.where(document_type: DocumentType.advisory_documentation)).not_to be_blank
          end
        end

        context "subcompany uci missing" do
          let(:subcompany) { build_stubbed(:subcompany, uci: nil) }

          it "fails" do
            expect(subject.call).to be_falsey
            expect(subject.errors).not_to be_blank
          end
        end
      end

      context "product does not have valid contract end date" do
        let(:product) { build :product, attributes.merge(contract_ended_at: nil) }

        it "fails" do
          expect(subject.call).to be_falsey
          expect(subject.errors).not_to be_blank
        end
      end
    end

    context "product does not have valid contract start date" do
      let(:product) { build :product, attributes.merge(contract_started_at: nil) }

      it "fails" do
        expect(subject.call).to be_falsey
        expect(subject.errors).not_to be_blank
      end
    end
  end

  context "product is in order_pending state" do
    let(:product) { build :product, attributes.merge(state: :intend_to_order) }

    it "fails" do
      expect(subject.call).to be_falsey
      expect(subject.errors).not_to be_blank
    end
  end
end
