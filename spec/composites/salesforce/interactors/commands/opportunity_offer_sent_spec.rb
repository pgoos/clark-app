# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/commands/opportunity_offer_sent"

RSpec.describe Salesforce::Interactors::Commands::OpportunityOfferSent, :integration do
  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:product) { create(:product) }
  let!(:offer) { create(:offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }
  let!(:opportunity) { create(:opportunity, mandate: mandate, sold_product: product, offer: offer) }

  it "sends offer" do
    expect(opportunity.state).to eq "created"
    object = described_class.new
    result = object.call(opportunity.id, "", {})
    expect(result).to be_successful
    expect(opportunity.reload.state).to eq "offer_phase"
  end
end
