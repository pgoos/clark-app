# frozen_string_literal: true

require "rails_helper"

RSpec.describe Salesforce::Interactors::BuildBusinessEventPayload, :integration do
  subject { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:business_event) { create(:business_event, entity: mandate, action: "accept") }

  it "returns event payload for customer accept" do
    expect(subject.(business_event, type: "Mandate", action: "accept").event_payload)
      .to be_kind_of Salesforce::Entities::Events::CustomerAccepted
  end

  it "returns event payload for customer revoke" do
    expect(subject.(business_event, type: "Mandate", action: "revoke").event_payload).to be_nil
  end
end
