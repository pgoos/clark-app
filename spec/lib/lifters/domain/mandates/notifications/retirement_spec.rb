# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::Notifications::Retirement do
  describe ".call" do
    let(:mandate)  { create(:mandate) }
    let(:product)  { create(:product, mandate: mandate) }
    let(:retirement_product) { create(:retirement_product, product: product, state: :details_available) }
    let(:products) { create_list(:product, 2, mandate: mandate) }
    let(:mailer) { double(RetirementProductMailer) }

    before do
      allow(Retirement::Messenger::AnalysedJob).to receive(:perform_later)
        .with(retirement_product.id, "retirement_product_analysed")

      allow(RetirementProductMailer).to receive(:retirement_product_analysed)
        .with(mandate, retirement_product).and_return(mailer)

      allow(mailer).to receive(:deliver_later)
    end

    context "when more than 50% of retirement_products are details_available" do
      before do
        product1 = create(:product, mandate: mandate)
        product2 = create(:product, mandate: mandate)

        create(:retirement_product, product: product1, state: :details_available)
        create(:retirement_product, product: product2, state: :information_required)

        described_class.call(retirement_product)
      end

      it { expect(mandate.interactions.count).to eq(1) }
      it { expect(mailer).to have_received(:deliver_later) }
      it { expect(Retirement::Messenger::AnalysedJob).to have_received(:perform_later) }
    end

    context "when less than 50% of retirement_products are details_available" do
      before do
        product1 = create(:product, mandate: mandate)
        product2 = create(:product, mandate: mandate)

        create(:retirement_product, product: product1, state: :information_required)
        create(:retirement_product, product: product2, state: :information_required)

        described_class.call(retirement_product)
      end

      it { expect(mandate.interactions.count).to eq(0) }
      it { expect(mailer).not_to have_received(:deliver_later) }
      it { expect(Retirement::Messenger::AnalysedJob).not_to have_received(:perform_later) }
    end

    context "when current retirement_product is not details_available" do
      let(:retirement_product) { create(:retirement_product, product: product, state: :information_required) }

      before do
        product1 = create(:product, mandate: mandate)
        product2 = create(:product, mandate: mandate)

        create(:retirement_product, product: product1, state: :details_available)
        create(:retirement_product, product: product2, state: :details_available)

        described_class.call(retirement_product)
      end

      it { expect(mandate.interactions.count).to eq(0) }
      it { expect(mailer).not_to have_received(:deliver_later) }
      it { expect(Retirement::Messenger::AnalysedJob).not_to have_received(:perform_later) }
    end
  end
end
