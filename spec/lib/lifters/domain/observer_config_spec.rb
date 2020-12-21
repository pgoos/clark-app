# frozen_string_literal: true

require "rails_helper"

require Rails.root.join("app", "composites", "customer", "repositories", "customer_repository")

RSpec.describe Domain::ObserverConfig do
  describe "#register_observers" do
    def clear_guard
      described_class.instance.instance_variable_set(:@initialized, false)
    end

    before { clear_guard }

    context "when runs once" do
      it "registers observers" do
        expect(Wisper).to receive(:clear).once
        expect(Document).to receive(:subscribe).twice
        described_class.register_observers
      end
    end

    context "when runs twice" do
      it "doesn't register observers second time" do
        expect(Wisper).to receive(:clear).once
        expect(Document).to receive(:subscribe).twice
        described_class.register_observers
        described_class.register_observers
      end
    end

    context "when something clears guard variable" do
      it "registers observers" do
        expect(Wisper).to receive(:clear).twice
        expect(Document).to receive(:subscribe).exactly(4).times
        described_class.register_observers
        clear_guard
        described_class.register_observers
      end
    end

    context "when run register_observers" do
      it "add Domain::Mandates::ProspectBecameSelfService to mandates objects" do
        expect(Mandate.new.listeners).to include(Domain::Mandates::SelfServiceCustomerCreated)
      end

      it "adds Domain::Mandates::PaybackCustomerAccepted to mandate listeners" do
        expect(Mandate.new.listeners).to include(Domain::Mandates::PaybackCustomerAccepted)
      end

      it "adds Domain::InquiryCategories::InquiryCategoryCreated to inquiry_category listeners" do
        expect(InquiryCategory.new.listeners).to include(Domain::InquiryCategories::InquiryCategoryCreated)
      end

      it "adds Domain::InquiryCategories::InquiryCategoryCancelled to inquiry_category listeners" do
        expect(InquiryCategory.new.listeners).to include(Domain::InquiryCategories::InquiryCategoryCancelled)
      end

      it "adds Domain::InquiryCategories::InquiryCategoryCompleted to inquiry_category listeners" do
        expect(InquiryCategory.new.listeners).to include(Domain::InquiryCategories::InquiryCategoryCompleted)
      end

      it "adds Domain::InquiryCategories::InquiryCategoryDeleted to inquiry_category listeners" do
        expect(InquiryCategory.new.listeners).to include(Domain::InquiryCategories::InquiryCategoryDeleted)
      end
    end
  end
end
