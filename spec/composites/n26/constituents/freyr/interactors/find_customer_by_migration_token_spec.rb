# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/find_customer_by_migration_token"

RSpec.describe N26::Constituents::Freyr::Interactors::FindCustomerByMigrationToken do
  subject { described_class.new(customer_repo: customer_repo) }

  context "when a customer exists with the migration token" do
    let(:token) { SecureRandom.alphanumeric(16) }
    let(:customer) do
      N26::Constituents::Freyr::Entities::Customer.new(
        id: 1,
        owner_ident: "n26",
        migration_state: "",
        info: { freyr: { migration_token: token } }
      )
    end

    let(:customer_repo) do
      instance_double(
        N26::Constituents::Freyr::Repositories::CustomerRepository,
        find_by_migration_token: customer
      )
    end

    it "calls the find_by_migration_token method in customer repository" do
      expect(customer_repo).to receive(:find_by_migration_token).with(token)
      subject.call(token)
    end

    it "returns a Utils::Interactor::Result instance" do
      result = subject.call(token)
      expect(result).to be_kind_of Utils::Interactor::Result
    end

    it "returns a successful result" do
      result = subject.call(token)
      expect(result).to be_successful
    end

    it "returns an instance of N26::Constituents::Freyr::Entities::Customer" do
      result = subject.call(token)
      expect(result.customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
    end
  end

  context "when no customer exists with the migration token" do
    let(:customer_repo) do
      instance_double(
        N26::Constituents::Freyr::Repositories::CustomerRepository,
        find_by_migration_token: nil
      )
    end

    it "returns an unsuccessful result" do
      result = subject.call("123")
      expect(result).not_to be_successful
    end

    it "returns the customer_not_found error" do
      result = subject.call("123")
      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_found"))
    end
  end
end
