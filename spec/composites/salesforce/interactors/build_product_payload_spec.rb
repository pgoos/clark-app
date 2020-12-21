# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/build_product_payload"

RSpec.describe Salesforce::Interactors::BuildProductPayload, :integration do
  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:company) { create(:company, name: "Company") }
  let!(:plan) { create(:plan, company: company) }
  let!(:product) { create(:product, { contract_ended_at: DateTime.current, company: company }) }
  let!(:offer) { create(:offer) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product, offer_id: offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }

  it "returns event payload for created type" do
    expect(subject.(product, action: "created").event_payload)
      .to be_kind_of Salesforce::Entities::Events::ProductCreated
  end

  it "returns event payload for updated type" do
    expect(subject.(product, action: "updated").event_payload)
      .to be_kind_of Salesforce::Entities::Events::ProductUpdated
  end
end
