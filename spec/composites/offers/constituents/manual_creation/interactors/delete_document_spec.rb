# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/interactors/delete_document"

RSpec.describe Offers::Constituents::ManualCreation::Interactors::DeleteDocument do
  let(:id) { 1 }
  let(:document) { double(:document) }

  before do
    allow_any_instance_of(
      Offers::Constituents::ManualCreation::Repositories::DocumentRepository
    ).to receive(:delete!).with(id).and_return(document)
  end

  it "returns success" do
    expect(described_class.new.call(id)).to be_success
  end
end
