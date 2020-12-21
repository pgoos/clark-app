# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/intiate_migration"

RSpec.describe N26::Constituents::Freyr::Interactors::InitiateMigration do
  subject {
    described_class.new(
      customer_repo: customer_repo,
      set_migration_token: set_migration_token
    )
  }

  let(:customer) do
    N26::Constituents::Freyr::Entities::Customer.new(
      id: 1,
      owner_ident: "n26"
    )
  end

  let(:email_verified_customer) do
    N26::Constituents::Freyr::Entities::Customer.new(
      id: 1,
      owner_ident: "n26",
      info: { "freyr": { "migration_state": "email_verified" } }
    )
  end

  let(:customer_repo) do
    instance_double(
      N26::Constituents::Freyr::Repositories::CustomerRepository,
      find_by_email: customer,
      update_migration_state: email_verified_customer
    )
  end

  let(:set_migration_token) do
    instance_double(
      N26::Constituents::Freyr::Interactors::SetMigrationToken,
      call: true
    )
  end

  let(:email) { "n26@email.com" }

  context "when a customer exists with the given email" do
    it "calls the find_by_email method in customer repository" do
      expect(customer_repo).to receive(:find_by_email).with(email)
      subject.call(email)
    end

    it "calls the set_migration_token interactor" do
      expect(set_migration_token).to receive(:call).with(customer.id)
      subject.call(email)
    end

    it "returns a Utils::Interactor::Result instance" do
      result = subject.call(email)
      expect(result).to be_kind_of Utils::Interactor::Result
    end

    it "returns a successful result" do
      result = subject.call(email)
      expect(result).to be_successful
    end

    it "returns an instance of N26::Constituents::Freyr::Entities::Customer" do
      result = subject.call(email)
      expect(result.customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
    end

    it "customer goes into `email_verified` state " do
      result = subject.call(email)
      expect(result.customer.info[:freyr][:migration_state]).to eq("email_verified")
    end
  end
end
