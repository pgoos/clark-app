# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::NotifyContractCancellation do
  let(:notifier) { double("Notifier", call: true) }
  let(:repository) { class_double("ProductsRepository") }
  let(:service)    { described_class.new(notifier, repository) }

  before { Timecop.freeze(Time.zone.now) }

  after  { Timecop.return }

  context "when CONTRACT_CANCELLATION_NOTIFIER_2020 is disabled" do
    before { FeatureSwitch.create!(key: Features::CONTRACT_CANCELLATION_NOTIFIER_2020, active: false) }

    it "calls the repository" do
      expect(repository).to receive(:retrieve_products_ending_at).with(Date.current + 120.days).and_return([])

      service.call
    end
  end

  context "when CONTRACT_CANCELLATION_NOTIFIER_2020 is active" do
    before { FeatureSwitch.create!(key: Features::CONTRACT_CANCELLATION_NOTIFIER_2020, active: true) }

    it "calls the repository" do
      expect(repository).to receive(:retrieve_products_eligible_for_cancellation_notification)
        .with(Date.current + 120.days, Domain::Products::NotifyContractCancellation::EXCLUDE_CATEGORIES)
        .and_return([])

      service.call
    end
  end

  context "when there are products" do
    let(:product) { OpenStruct.new(id: 1, mandate_id: 1001, category_name: "pkv") }
    let(:products) { [product] }

    before do
      allow(repository).to receive(:retrieve_products_ending_at).and_return(products)
    end

    it "calls notifier" do
      expect(notifier).to receive(:call).with(product.id)
      service.call
    end
  end

  context "when there is no products" do
    let(:products) { [] }

    before do
      allow(repository).to receive(:retrieve_products_ending_at).and_return(products)
    end

    it "does not call notifier" do
      expect(notifier).not_to receive(:call)

      service.call
    end
  end
end
