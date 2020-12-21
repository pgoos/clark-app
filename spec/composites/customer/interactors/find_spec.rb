# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/find"

RSpec.describe Customer::Interactors::Find, :integration do
  it "returns customer" do
    customer = create(:customer)
    result = subject.call(customer.id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Entities::Customer
    expect(result.customer.id).to eq customer.id
  end

  it "returns an error if customer doesn't exist" do
    result = subject.call(999)
    expect(result).not_to be_successful
    expect(result.errors).to include "Customer not found"
  end
end
