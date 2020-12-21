# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::UpgradeJourney::Interactors::UpdateProfile do
  subject(:update_profile) do
    described_class.new(customer_repo: customer_repo, profile_repo: profile_repo)
  end

  let(:customer_id) { 999 }
  let(:customer_repo) { double :repo, find: nil, update!: true }
  let(:profile_repo) { double :repo, update!: true }
  let(:validator) { double :validator, call: validator_response }
  let(:validator_response) { double(:response, failure?: false) }
  let(:updated_customer) { double :customer }

  let(:customer) do
    double(
      :customer,
      upgrade_journey_state: "profile",
      mandate_state: "in_creation",
      customer_state: "self_service"
    )
  end

  let(:customer_attributes) { {upgrade_journey_state: "signature"} }
  let(:profile_attributes) do
    {
      gender: "male",
      first_name: "Hero",
      last_name: "Alam",
      birthdate: "01.01.1980",
      phone_number: "+491111111111",
      street: "tongi",
      house_number: "5",
      city: "Frankfurt",
      zipcode: "63065"
    }
  end

  it "updates customer state and profile attributes" do
    expect(customer_repo).to receive(:update!).with(customer_id, customer_attributes)
    expect(customer_repo).to receive(:find).and_return(customer, updated_customer)
    expect(profile_repo).to receive(:update!).with(customer_id, profile_attributes)

    result = update_profile.(customer_id, profile_attributes)

    expect(result).to be_successful
    expect(result.customer).to eq updated_customer
  end

  context "when customer does not exist" do
    it "returns failure" do
      result = update_profile.(customer_id, profile_attributes)
      expect(result).to be_failure
    end
  end

  context "with invalid attributes" do
    let(:errors) { double(:errors, to_h: nil) }
    let(:validator_response) { double(:response, failure?: true, errors: errors) }

    it "returns failure" do
      result = update_profile.(customer_id, profile_attributes)
      expect(result).to be_failure
    end
  end
end
