# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/find_by_installation_id"

RSpec.describe Customer::Interactors::FindByInstallationId do
  it "returns customer" do
    lead = create(:device_lead, :with_mandate)
    installation_id = lead.installation_id
    result = subject.call(installation_id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Entities::Customer
    expect(result.customer.id).to eq lead.mandate_id
  end

  it "returns an error if customer doesn't exist" do
    result = subject.call(999)
    expect(result).not_to be_successful
    expect(result.errors).to include "Customer not found"
  end
end
