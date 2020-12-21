# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/set_migration_token"
require "composites/n26/constituents/freyr/entities/customer"

RSpec.describe N26::Constituents::Freyr::Interactors::SetMigrationToken do
  subject { described_class.new(customer_repo: customer_repo) }

  let(:owner_ident) { "n26" }
  let(:customer) {
    instance_double(N26::Constituents::Freyr::Entities::Customer, id: 1, owner_ident: owner_ident)
  }
  let(:customer_repo) {
    double(
      find: customer,
      save_migration_token!: customer
    )
  }

  before do
    allow(N26Mailer).to receive_message_chain(:migration_instructions, :deliver_later).and_return(true)
  end

  context "when customer doesn't exist" do
    let(:customer_repo) { double :repo, find: nil }

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end
  end

  context "when customer is not owned by 26" do
    let(:customer) {
      instance_double(N26::Constituents::Freyr::Entities::Customer, id: 1, owner_ident: "clark")
    }

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end
  end

  context "when all the validations are correct" do
    it "returns successful result" do
      result = subject.call(customer.id)
      expect(result).to be_successful
    end

    it "calls the method to save the migration token for customer" do
      expect(customer_repo).to receive(:save_migration_token!)
      subject.call(customer.id)
    end

    it "sends email with migration instructions to customer" do
      expect(N26Mailer).to receive_message_chain(:migration_instructions, :deliver_later)
      subject.call(customer.id)
    end
  end

  describe "#generate_token" do
    it "generates a token of length 16" do
      token = subject.send(:generate_token)
      expect(token.length).to eq(16)
    end
  end
end
