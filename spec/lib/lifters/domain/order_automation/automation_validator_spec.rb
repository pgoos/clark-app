# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OrderAutomation::AutomationValidator do
  describe "#valid?" do
    subject { described_class.new(product) }

    let(:plan) { build_stubbed(:plan, subcompany: subcompany) }
    let(:mandate) { build_stubbed(:mandate, iban: "iban") }
    let(:subcompany) do
      build_stubbed(:subcompany, :with_order_email, quality_pool_broker_nr: "QP Number", contact_type: "quality_pool", uci: "uci")
    end
    let(:product) do
      build_stubbed(:product, state: "order_pending", plan: plan, mandate: mandate, contract_started_at: 1.day.from_now,
        contract_ended_at: 3.days.from_now)
      end

    before do
      # FactoryBot build_stubbed does not support has_one :through
      allow(product).to receive(:subcompany).and_return subcompany
      allow(product).to receive(:suhk?).and_return subcompany
    end

    it "is valid" do
      expect(subject).to be_valid
    end

    it "is not valid with empty uci" do
      subcompany.uci = nil
      expect(subject).not_to be_valid
      expect(subject.errors.count).to eq 1
      expect(subject.errors.full_messages).to eq ["Uci needs to be present"]
    end

    it "is valid with empty uci and softfair turned off" do
      allow(Settings).to receive_message_chain(:softfair, :show).and_return(false)

      subcompany.uci = nil
      expect(subject).to be_valid
    end

    it "is not valid with empty subcompany" do
      allow(product).to receive(:subcompany).and_return nil
      expect(subject).not_to be_valid
      expect(subject.errors.count).to eq 1
      expect(subject.errors[:subcompany]).to eq [I18n.t("errors.messages.blank")]
    end

    it "is not valid when product already has documentation" do
      allow(product).to receive(:has_cover_note?).and_return(false)
      allow(product).to receive(:has_advisory_documentation?).and_return(true)

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["cover note and advisory documentation present"]
    end

    context "without valid iban" do
      let(:mandate) { build_stubbed(:mandate, iban: nil) }

      it "is not valid anymore" do
        expect(subject).not_to be_valid
        expect(subject.errors.count).to eq 1
        expect(subject.errors.full_messages).to eq ["Iban needs to be present"]
      end
    end

    it "is not valid when the subcompany does not have an order e-mail" do
      allow(product).to receive(:suhk?).and_return false

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["SUHK not valid"]
    end

    it "is not valid when the product is not order_pending" do
      allow(product).to receive(:state).and_return "created"

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Status has to be order_pending"]
    end

    it "is not valid when the product miss contract_started_at" do
      allow(product).to receive(:contract_started_at).and_return nil

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Contract started at muss ausgefüllt werden"]
    end

    it "is not valid when the product is not contract_ended_at" do
      allow(product).to receive(:contract_ended_at).and_return nil

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Contract ended at muss ausgefüllt werden"]
    end

    context "with order email" do
      it "returns the correct errors" do
        subcompany.contact_type = "direct_agreement"
        subcompany.direct_agreement_broker_nr = "Direct Agreement Number"
        subcompany.order_email = nil

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to eq ["Order email does not exist"]

        subcompany.contact_type = "quality_pool"
        subcompany.quality_pool_broker_nr = "QP number"
        expect(subject).to be_valid

        subcompany.contact_type = "fonds_finanz"
        subcompany.fonds_finanz_broker_nr = "FF number"
        expect(subject).to be_valid

        subcompany.contact_type = nil
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).not_to include "Order email does not exist"
      end
    end

    context "with contact type validation" do
      it "returns the correct errors" do
        subcompany.contact_type = nil
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to eq ["No standard connection for new contracts set"]

        subcompany.contact_type = "undefined"
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to eq ["No standard connection for new contracts set"]

        subcompany.contact_type = "quality_pool"
        expect(subject).to be_valid
      end
    end

    context "with correct broker numbers" do
      it "returns an error if broker number is not set" do
        subcompany.contact_type = "direct_agreement"
        subcompany.direct_agreement_broker_nr = nil
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to eq ["Direktanbindung number needs to be set"]

        subcompany.direct_agreement_broker_nr = "1234"
        expect(subject).to be_valid
      end
    end
  end
end
