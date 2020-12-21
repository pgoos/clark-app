# frozen_string_literal: true

require "rails_helper"

RSpec.describe Salesforce::Interactors::BuildCustomerPayload, :integration do
  subject { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }

  it "returns event payload for customer demand check completed" do
    expect(subject.(mandate, type: "Mandate", action: "demand-check-completed").event_payload)
      .to be_kind_of Salesforce::Entities::Events::CustomerDemandCheckCompleted
  end
end
