# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::ApiPartners::DataSynchronizer do
  let(:logger) { Logger.new("/dev/null") }
  let(:mandate) { create :mandate, :owned_by_partner }
  let(:synchronizer) { described_class.new(logger, "partner", mandate.id) }
  let(:queue_client) { Platform::ApiPartners::Clients::MockClient }

  before do
    allow(Features).to receive(:active?).and_call_original
    allow(Features).to receive(:active?).with(Features::API_NOTIFY_PARTNERS).and_return(true)
  end

  describe "#synchronize" do
    context "called with a valid mandate with no products, advices or inquiry_categories" do
      before do
        allow(Mandate).to receive(:find).and_return(mandate)
        synchronizer.synchronize
      end

      it "publishes the mandate" do
        expect(synchronizer.synced_entity_counts[:Mandate]).to eq 1
      end

      it "publishes no products" do
        expect(synchronizer.synced_entity_counts[:Product]).to eq 0
      end

      it "publishes no advices" do
        expect(synchronizer.synced_entity_counts[:Advice]).to eq 0
      end

      it "publishes no inquiry_categories" do
        expect(synchronizer.synced_entity_counts[:InquiryCategory]).to eq 0
      end

      it "calls the #publish_entity_state_and_data method" do
        expect(synchronizer).to receive(:publish_entity_state_and_data)
        synchronizer.synchronize
      end

      it "publishes the mandate data" do
        expect(mandate).to receive(:restream_entity)
        synchronizer.synchronize
      end
    end

    context "called with a valid mandate with products" do
      let!(:product) { create :product, mandate: mandate }
      let!(:second_product) { create :product, mandate: mandate }

      it "publishes all products" do
        synchronizer.synchronize
        expect(synchronizer.synced_entity_counts[:Product]).to eq mandate.products.count
      end
    end

    context "called with a valid mandate with products and advices" do
      let!(:product) { create :product, mandate: mandate }
      let!(:second_product) { create :product, mandate: mandate }
      let!(:advice) { create :advice, mandate: mandate, product: product }
      let!(:second_advice) { create :advice, mandate: mandate, product: second_product }

      before do
        synchronizer.synchronize
      end

      it "publishes all products" do
        expect(synchronizer.synced_entity_counts[:Product]).to eq mandate.products.count
      end

      it "publishes all advices" do
        expect(synchronizer.synced_entity_counts[:Product]).to eq 2
      end
    end

    context "called with a valid mandate with inquiry categories" do
      let!(:inquiry) { create :inquiry, mandate: mandate }
      let!(:inquiry_category) { create :inquiry_category, inquiry: inquiry }
      let!(:second_inquiry_category) { create :inquiry_category, inquiry: inquiry }

      it "publishes all inquiry_categories" do
        synchronizer.synchronize
        expect(synchronizer.synced_entity_counts[:InquiryCategory]).to eq InquiryCategory.by_mandate(mandate).count
      end
    end

    context "when API_NOTIFY_PARTNERS is off" do
      it "does not publish the mandate" do
        allow(Features).to receive(:active?).with(Features::API_NOTIFY_PARTNERS).and_return(false)
        expect(synchronizer.synced_entity_counts[:Mandate]).to eq 0
      end
    end

    context "called with an inaccessible mandate" do
      let(:inaccessible_mandate) { create :mandate }
      let(:synchronizer) { described_class.new(logger, "partner", inaccessible_mandate.id) }
      let!(:inaccessible_product) { create :product, mandate: inaccessible_mandate }
      let!(:inaccessible_advice) { create :advice, mandate: inaccessible_mandate, product: inaccessible_product }
      let!(:inaccessible_inquiry) { create :inquiry, mandate: inaccessible_mandate }
      let!(:inaccessible_inquiry_category) { create :inquiry_category, inquiry: inaccessible_inquiry }

      before do
        synchronizer.synchronize
      end

      it "does not publish the mandate" do
        expect(synchronizer.synced_entity_counts[:Mandate]).to eq 0
      end

      it "does not publish any products" do
        expect(synchronizer.synced_entity_counts[:Product]).to eq 0
      end

      it "does not publish any advices" do
        expect(synchronizer.synced_entity_counts[:Advice]).to eq 0
      end

      it "does not publish any inquiry categories" do
        expect(synchronizer.synced_entity_counts[:InquiryCategory]).to eq 0
      end
    end
  end
end
