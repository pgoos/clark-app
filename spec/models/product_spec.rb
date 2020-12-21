# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  let(:product) { build :product, state: "takeover_requested" }

  context "when products state updated with state machine" do
    it "does not trigger 'manual_state_reset' business event" do
      expect(BusinessEvent).not_to \
        receive(:audit).with(product, ::Domain::Products::ManualStateReset::MANUAL_STATE_RESET)

      product.take_under_management!
    end
  end

  describe "#from_gkv?" do
    before { allow(Settings).to receive_message_chain("categories.gkv.enabled").and_return gkv_enabled }

    context "when product category is gkv" do
      let(:category) { build(:category_gkv) }
      let(:plan) { build(:plan, category: category) }
      let(:product) { build(:product, plan: plan) }

      context "and setting is disabled" do
        let(:gkv_enabled) { false }

        it { expect(product.from_gkv?).to eq false }
      end

      context "and settings is enabled" do
        let(:gkv_enabled) { true }

        it { expect(product.from_gkv?).to eq true }
      end
    end

    context "when product category is not gkv" do
      let(:gkv_enabled) { true }

      it { expect(product.from_gkv?).to eq false }
    end
  end

  describe "#premium_price" do
    subject { product }

    let(:product) { create :product, :customer_provided }

    context "transitioning customer_provided to terminated" do
      before { product.state = :customer_terminated }

      it { is_expected.not_to validate_numericality_of(:premium_price).is_greater_than(0) }
    end

    context "transitioning customer_provided to details_saved or other state" do
      before { product.state = :details_saved }

      it { is_expected.to validate_numericality_of(:premium_price).is_greater_than(0) }
    end
  end

  describe "#number" do
    subject { product }

    let(:product) { create :product, :customer_provided }

    context "transitioning customer_provided to terminated" do
      before { product.state = :customer_terminated }

      it { is_expected.not_to validate_presence_of(:number) }
    end

    context "transitioning customer_provided to details_saved or other state" do
      before { product.state = :details_saved }

      it { is_expected.to validate_presence_of(:number) }
    end
  end

  describe "#contract_started_at" do
    subject { product }

    let(:product) { create :product, :customer_provided }

    context "transitioning customer_provided to terminated" do
      before { product.state = :customer_terminated }

      it { is_expected.not_to validate_presence_of(:contract_started_at) }
    end

    context "transitioning customer_provided to details_saved or other state" do
      before { product.state = :details_saved }

      it { is_expected.to validate_presence_of(:contract_started_at) }
    end
  end

  describe "#send_to_salesforce" do
    it "sends create action to salesforce" do
      allow(Settings.salesforce).to receive(:enable_send_opportunity_events).and_return(true)
      mock_lamda = ->(args) { args }
      allow(::Salesforce::Container).to receive(:resolve)
        .with("public.interactors.perform_send_event_job")
        .and_return(mock_lamda)

      expect(::Salesforce::Container).to receive(:resolve)
      create(:product)
    end

    it "sends update action to salesforce" do
      product = create(:product)
      allow(Settings.salesforce).to receive(:enable_send_opportunity_events).and_return(true)
      mock_lamda = ->(args) { args }
      allow(::Salesforce::Container).to receive(:resolve)
        .with("public.interactors.perform_send_event_job")
        .and_return(mock_lamda)

      expect(::Salesforce::Container).to receive(:resolve)
      product.update(notes: "bla")
    end
  end
end
