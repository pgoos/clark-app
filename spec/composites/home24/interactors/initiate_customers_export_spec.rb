# frozen_string_literal: true

require "rails_helper"
require "composites/home24/interactors/initiate_customers_export"
require "composites/home24/repositories/customer_repository"
require "composites/home24/repositories/profile_repository"
require "composites/home24/repositories/product_repository"

RSpec.describe Home24::Interactors::InitiateCustomersExport, :integration do
  subject { described_class.new(customer_repo: customer_repo, profile_repo: profile_repo) }

  let(:customer) {
    instance_double(
      Home24::Entities::Customer,
      id: 1,
      home24_source: true,
      order_number: "10112312321",
      home24_data: {}
    )
  }

  let(:profile) do
    instance_double(
      Home24::Entities::Profile,
      gender: "male",
      first_name: "Hero",
      last_name: "Alam",
      birthdate: DateTime.parse("01.01.1980"),
      email: "test@clark.de",
      address: address,
      phone: phone
    )
  end

  let(:address) {
    instance_double(
      Home24::Entities::Address,
      street: "tongi",
      house_number: "5",
      city: "Frankfurt",
      zipcode: "63065"
    )
  }

  let(:phone) { instance_double(Home24::Entities::Phone, number: "+491111111111") }

  let(:customer_repo) do
    instance_double(
      Home24::Repositories::CustomerRepository,
      customers_to_export: [customer],
      save_export_state: true
    )
  end

  let(:profile_repo) do
    instance_double(
      Home24::Repositories::ProfileRepository,
      find: profile
    )
  end

  let(:message_to_send) {
    { mandate_id: customer.id,
      broker_number: described_class::NEODIGITAL_BROKER_NUMBER,
      insurance_category: Home24::Entities::Product::FREE_PRODUCT_CATEGORY,
      order_id: customer.order_number,
      title: "",
      name_2: "",
      citizenship: "",
      mobile_phone_number: "",
      gross_annual_premium: described_class::GROSS_ANNUAL_PREMIUM,
      brokerage_rate: described_class::BROKERAGE_RATE,
      tariff: Home24::Entities::Product::FREE_PRODUCT_TARIFF,
      deductible_amount: described_class::DEDUCTIBLE_AMOUNT,
      sum_insured: described_class::SUM_INSURED,
      salutation: I18n.t(Enum::PersonalPhrases::SALUTATION[profile.gender]),
      first_name: profile.first_name,
      last_name: profile.last_name,
      birthdate: profile.birthdate.iso8601,
      street: profile.address.street,
      house_number:  profile.address.house_number,
      zipcode: profile.address.zipcode,
      city: profile.address.city,
      private_phone_number: profile.phone.number,
      email: profile.email,
      contract_started_at: Time.zone.now.beginning_of_day,
      contract_ended_at: Time.zone.now.end_of_day + Home24::Entities::Product::FREE_CONTRACT_INTERVAL }.to_json
  }

  it "calls customers_to_export method in customer repository" do
    expect(customer_repo)
      .to receive(:customers_to_export)
      .with(Home24::Entities::Product::FREE_PLAN_IDENT,
            Home24::Entities::Product::ACTIVE_STATES,
            described_class::NOT_COUNTABLE_CATEGORY_IDENTIFIERS,
            max_no_of_customers: nil,
            forced_customer_ids: [])

    subject.call
  end

  it "calls find method on profile_repo for customer that has to be exported" do
    expect(profile_repo).to receive(:find).with(customer.id, include_address: true, include_phone: true)
    subject.call
  end

  it "expects result of interactor to be Utils::Interactor::Result instance" do
    result = subject.call
    expect(result).to be_kind_of Utils::Interactor::Result
  end

  it "expects result of interactor to be successfully" do
    result = subject.call
    expect(result).to be_successful
  end

  it "push the message with right data to queue using sqsclient" do
    sqs_client = double(send_message: true)

    allow(Home24::Factories::Sqs::Client).to receive(:build).and_return(sqs_client)

    expect(sqs_client).to receive(:send_message).with(message_to_send)
    subject.call
  end

  it "save export state for customer" do
    expect(customer_repo)
      .to receive(:save_export_state).with(customer.id, Home24::Entities::Customer::ExportState::INITIATED)

    subject.call
  end

  context "when max_no_of_customers is passed" do
    let(:max_no_of_customers) { 1 }

    it "calls customers_to_export method in customer repository with max_no_of_customers" do
      expect(customer_repo)
        .to receive(:customers_to_export)
        .with(Home24::Entities::Product::FREE_PLAN_IDENT,
              Home24::Entities::Product::ACTIVE_STATES,
              described_class::NOT_COUNTABLE_CATEGORY_IDENTIFIERS,
              max_no_of_customers: max_no_of_customers,
              forced_customer_ids: [])

      subject.call(max_no_of_customers: max_no_of_customers)
    end
  end

  context "when forced_customer_ids is passed" do
    let(:forced_customer_ids) { [1] }

    it "calls customers_to_export method in customer repository with max_no_of_customers" do
      expect(customer_repo)
        .to receive(:customers_to_export)
        .with(Home24::Entities::Product::FREE_PLAN_IDENT,
              Home24::Entities::Product::ACTIVE_STATES,
              described_class::NOT_COUNTABLE_CATEGORY_IDENTIFIERS,
              max_no_of_customers: nil,
              forced_customer_ids: forced_customer_ids)

      subject.call(forced_customer_ids: forced_customer_ids)
    end
  end

  context "when the message is not sent to the queue" do
    let(:sqs_client) { double(send_message: false) }

    before do
      allow(Home24::Factories::Sqs::Client).to receive(:build).and_return(sqs_client)
    end

    it "doesn't change the export state" do
      expect(customer_repo).not_to receive(:save_export_state)

      subject.call
    end
  end
end
