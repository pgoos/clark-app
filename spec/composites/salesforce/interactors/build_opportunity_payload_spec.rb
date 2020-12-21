# frozen_string_literal: true

require "rails_helper"

RSpec.describe Salesforce::Interactors::BuildOpportunityPayload, :integration do
  subject { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:product) { create(:product) }
  let!(:offer) { create(:offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product, offer: offer) }

  it "returns event payload for known type" do
    expect(subject.(opportunity, action: "sold").event_payload)
      .to be_kind_of Salesforce::Entities::Events::OpportunityWon
  end

  it "returns event payload for type initiated" do
    expect(subject.(opportunity, action: "initiated").event_payload)
      .to be_kind_of Salesforce::Entities::Events::OpportunityInitiated
  end

  it "returns event payload for type lost" do
    expect(subject.(opportunity, action: "lost").event_payload)
      .to be_kind_of Salesforce::Entities::Events::OpportunityLost
  end

  it "returns event payload for type offer created" do
    expect(subject.(opportunity, action: "offer_created").event_payload)
      .to be_kind_of Salesforce::Entities::Events::OpportunityOfferCreated
  end

  it "returns event payload for type offer accepted" do
    expect(subject.(opportunity, action: "offer_accepted").event_payload)
      .to be_kind_of Salesforce::Entities::Events::OpportunityOfferAccepted
  end
end
