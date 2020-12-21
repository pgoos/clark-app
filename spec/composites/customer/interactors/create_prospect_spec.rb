# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/create_prospect"

RSpec.describe Customer::Interactors::CreateProspect do
  let(:ip) { Faker::Internet.ip_v4_address }
  let(:installation_id) { Faker::Internet.device_token }

  it "returns created prospect customer" do
    result = subject.call(ip, installation_id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.customer).to be_kind_of Customer::Entities::Customer
    expect(result.customer.registered_with_ip).to eq ip
    expect(result.customer.customer_state).to eq "prospect"
    expect(result.customer.installation_id).to eq installation_id
    expect(result.customer.source_data).to eq("anonymous_lead" => true)
  end

  it "returns validation error if installation_id already exists" do
    repo = double(:repo, installation_id_exists?: true)
    visit_repo = double(:visit_repo, find: nil)
    interactor = described_class.new customers_repository: repo, visits_repository: visit_repo
    result = interactor.call(ip, installation_id)
    expect(result).to be_failure
    expect(result.errors).not_to be_empty
  end

  it "handles the errors from repository" do
    repo = Customer::Repositories::CustomerRepository.new
    visit_repo = double(:visit_repo, find: nil)
    allow(repo).to receive(:create_prospect!).and_raise(Customer::Repositories::CustomerRepository::Error)
    interactor = described_class.new customers_repository: repo, visits_repository: visit_repo
    result = interactor.call(ip)
    expect(result).not_to be_successful
  end

  context "when it has tracking info" do
    let(:visit) do
      Customer::Entities::Visit.new(
        id: "12345678-1234-1234-1234-12345678",
        visitor_id: "87654321-4321-4321-4321-876543211",
        ip: "127.0.0.1",
        referrer: "https://www.google.de",
        landing_page: "https://www.clark.de/de",
        utm_source: "CoolAds",
        utm_campaign: "campaign",
        utm_term: "term",
        utm_content: "content",
        utm_medium: "medium"
      )
    end

    let(:expected_adjust) do
      {
        "network" => "CoolAds",
        "campaign" => "campaign",
        "creative" => "term",
        "adgroup" => "content",
        "medium" => "medium"
      }
    end

    let(:interactor) do
      repo = Customer::Repositories::CustomerRepository.new
      visit_repo = double(:visit_repo, find: visit)

      described_class.new customers_repository: repo, visits_repository: visit_repo
    end

    it "returns created prospect customer with tracking info" do
      result = interactor.call(ip, installation_id, visit.id)
      customer = result.customer

      expect(customer.source_data["adjust"]).to eq(expected_adjust)
    end
  end
end
