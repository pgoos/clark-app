# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/find_profile"

RSpec.describe Customer::Interactors::FindProfile, :integration do
  it "returns profile" do
    customer = create(:customer)
    result = subject.call(customer.id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.profile).to be_kind_of Customer::Entities::Profile
    expect(result.profile.customer_id).to eq customer.id
  end

  it "returns an error if customer doesn't exist" do
    result = subject.call(999)
    expect(result).not_to be_successful
    expect(result.errors).to include "Customer not found"
  end
end
