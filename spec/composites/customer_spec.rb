# frozen_string_literal: true

require "rails_helper"
require "composites/customer"

RSpec.describe Customer, :integration do
  let(:ip) { Faker::Internet.ip_v4_address }
  let(:installation_id) { Faker::Internet.device_token }
  let(:attributes) do
    {
      gender: "female",
      first_name: "Marie",
      last_name: "Curie",
      birthdate: "1934-07-04",
      phone_number: "+49#{ClarkFaker::PhoneNumber.phone_number}",
      iban: "DE89 3704 0044 0532 0130 00",
      street: "Goethestraße",
      house_number: "10",
      zipcode: "60313",
      city: "Frankfurt am Main"
    }.with_indifferent_access
  end

  it "creates a new prospect customer" do
    result = described_class.create_prospect(ip)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Entities::Customer
    expect(result.customer.registered_with_ip).to eq ip
    expect(result.customer.customer_state).to eq "prospect"
  end

  it "finds and returns a customer" do
    customer = create(:customer)
    result = described_class.find(customer.id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Entities::Customer
    expect(result.customer.id).to eq customer.id
  end

  it "finds and returns a customer profile" do
    customer = create(:customer)
    result = described_class.find_profile(customer.id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.profile).to be_kind_of Customer::Entities::Profile
    expect(result.profile.customer_id).to eq customer.id
  end

  it "updates installation_id and returns updated customer" do
    customer = create(:customer, :prospect)
    result = described_class.update_installation_id(customer.id, installation_id)
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Entities::Customer
    expect(result.customer.id).to eq customer.id
    expect(result.customer.installation_id).to eq installation_id
  end

  it "finds and returns a customer privacy setting" do
    customer = create(:customer)
    create(:privacy_setting, mandate_id: customer.id)
    result = described_class.find_privacy_settings(customer.id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.privacy_settings).to be_kind_of Customer::Entities::PrivacySettings
    expect(result.privacy_settings.mandate_id).to eq customer.id
  end

  it "updates a customer profile" do
    customer = create(:customer)
    result = described_class.update_profile(customer.id, attributes)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful

    mandate = Mandate.find(customer.id)
    expect(mandate.gender).to eql(attributes[:gender])
    expect(mandate.first_name).to eql(attributes[:first_name])
    expect(mandate.last_name).to eql(attributes[:last_name])
    expect(mandate.birthdate.strftime("%F")).to eql(attributes[:birthdate])
    expect(mandate.phone).to eql(attributes[:phone_number])
    expect(mandate.send(:iban)).to eql(attributes[:iban].gsub(" ", ""))
    expect(mandate.street).to eql(attributes[:street])
    expect(mandate.house_number).to eql(attributes[:house_number])
    expect(mandate.zipcode).to eql(attributes[:zipcode])
    expect(mandate.city).to eql(attributes[:city])
  end

  it "finds a customer by installation_id" do
    lead = create(:device_lead, :with_mandate)
    installation_id = lead.installation_id
    result = described_class.find_by_installation_id(installation_id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Entities::Customer
    expect(result.customer.id).to eq lead.mandate_id
  end

  it "requests corrections in upgrade" do
    customer = create(:customer, :unapproved_mandate_customer)
    result = described_class.request_corrections_in_upgrade(customer.id)
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Constituents::UpgradeJourney::Entities::Customer
    expect(result.customer.customer_state).to eq "self_service"
    expect(result.customer.mandate_state).to eq "in_creation"
    expect(result.customer.upgrade_journey_state).to eq "profile"
  end

  it "returns if customer permitted to access instant advice" do
    customer = create(:customer)
    allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(true)
    result = described_class.instant_advice_permitted?(customer.id)
    expect(result).to be_successful
    expect(result).to be_kind_of Utils::Interactor::Result
  end
end
