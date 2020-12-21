# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/interactors/create_or_update_document"

RSpec.describe Offers::Constituents::ManualCreation::Interactors::CreateOrUpdateDocument do
  context "with valid params" do
    let(:attributes) { double(:attributes, symbolize_keys: {}) }
    let(:document) { double(:document) }

    before do
      allow_any_instance_of(
        described_class
      ).to receive(:valid?).and_return(true)

      allow_any_instance_of(
        Offers::Constituents::ManualCreation::Repositories::DocumentRepository
      ).to receive(:create_or_update!).and_return(document)
    end

    it "exposes document" do
      expect(subject.call(attributes).document).to eq document
    end
  end
end
