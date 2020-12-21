# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/send_opportunity_event"

RSpec.describe Salesforce::Interactors::SendOpportunityEvent, :integration do
  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:product) { create(:product) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product) }

  it "is successful" do
    object = described_class.new
    allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
    result = object.call(opportunity.id, "Opportunity", "sold")
    expect(result).to be_successful
  end

  it "is success with nil" do
    object = described_class.new
    allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
    result = object.call(10_000, "Opportunity", "sold")
    expect(result).to be_successful
  end

  it "is error" do
    object = described_class.new
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
    expect {
      object.call(opportunity.id, "Opportunity", "sold")
    }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
  end
end
