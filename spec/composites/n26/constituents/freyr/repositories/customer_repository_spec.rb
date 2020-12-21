# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/repositories/customer_repository"
require "composites/n26/constituents/freyr/entities/customer"

RSpec.describe N26::Constituents::Freyr::Repositories::CustomerRepository do
  subject(:repo) { described_class.new }

  let(:owner_ident) { "n26" }
  let(:state) { "accepted" }
  let(:mandate) do
    create(:mandate, :accepted, owner_ident: owner_ident, info: { "freyr_imported" => true }).tap do |mandate|
      create(:user, mandate: mandate)
    end
  end

  describe "#find" do
    it "returns an entity" do
      customer = repo.find(mandate.id)
      expect(customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
      expect(customer.id).to eq mandate.id
      expect(customer.owner_ident).to eq mandate.owner_ident
      expect(customer.email).to eq mandate.user.email
      expect(customer.info).to eq mandate.info
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find(999)).to be_nil
      end
    end
  end

  describe "#save_migration_token!" do
    let(:token) { "Koo1590148345572" }

    it "returns customer entity and saves the token" do
      customer = repo.save_migration_token!(mandate.id, token)

      expect(customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
      expect(customer.id).to eq mandate.id
      expect(mandate.reload.info["freyr"]["migration_token"]).to eq token
      expect(mandate.info["freyr"]["token_generated_at"]).not_to be_nil
    end
  end

  describe "#find_by_email" do
    let(:email) { "test@test.com" }

    let!(:user) {
      create(
        :user,
        email: email,
        mandate: mandate
      )
    }

    it "returns entity with aggregated data" do
      customer = repo.find_by_email(email)

      expect(customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
      expect(customer.id).to eq(mandate.id)
      expect(customer.owner_ident).to eq(mandate.owner_ident)
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find_by_email("something@something.com")).to be_nil
      end
    end
  end

  describe "#update!" do
    let(:customer) { create(:mandate) }

    let(:params) { { owner_ident: "clark", accessible_by: ["clark"] } }

    it "update mandate and returns true" do
      expect(repo.update!(customer.id, params)).to eq(true)

      mandate = Mandate.find(customer.id)
      expect(mandate.owner_ident).to eq(params[:owner_ident])
      expect(mandate.accessible_by).to eq(params[:accessible_by])
    end
  end

  describe "#update_account_password!" do
    let(:user) { create(:user) }
    let(:customer) { create(:mandate, user: user) }
    let(:password) { "Test12345" }

    it "updates password for account of customer and returns true" do
      expect(repo.update_account_password!(customer.id, password)).to eq(true)

      mandate = Mandate.find(customer.id)
      expect(mandate.user.valid_password?(password)).to be_truthy
    end
  end

  describe "#clear_migration_token!" do
    let(:mandate) { create(:mandate, :freyr_with_data) }

    it "updates clears migration token and returns customer entity" do
      customer = repo.clear_migration_token!(mandate.id)

      expect(customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
      expect(customer.id).to eq(mandate.id)

      mandate = Mandate.find(customer.id)
      expect(mandate.info["freyr"]["migration_token"]).to be_nil
      expect(mandate.info["freyr"]["token_generated_at"]).to be_nil
    end
  end

  describe "#find_by_migration_token" do
    let(:token) { SecureRandom.alphanumeric(16) }

    let!(:mandate_with_token) {
      create(:mandate, info: { "freyr": { "migration_token": token } })
    }

    it "returns entity with aggregated data" do
      customer = repo.find_by_migration_token(token)

      expect(customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
      expect(customer.id).to eq(mandate_with_token.id)
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find_by_migration_token("abcdefgh12345678")).to be_nil
      end
    end
  end

  describe "#customers_to_send_reminder" do
    let(:started_migration_before) { 7.days.ago.end_of_day }
    let(:reminder_document_type) { "n26_migration_reminder" }

    context "when there is not any customer to send migration reminder email" do
      it "returns empty array" do
        customers = repo.customers_to_send_reminder(started_migration_before, reminder_document_type)

        expect(customers.size).to be_zero
      end
    end

    context "when there is a customer to send reminder" do
      let!(:mandate) { create(:mandate, :freyr_with_data, token_generated_at: started_migration_before - 5.hours) }

      it "returns entity with aggregated data" do
        customers = repo.customers_to_send_reminder(started_migration_before, reminder_document_type)

        expect(customers.size).to eq 1
        expect(customers[0]).to be_kind_of N26::Constituents::Freyr::Entities::Customer
        expect(customers[0].id).to eq mandate.id
      end
    end

    context "when there is a customer to send reminder but remainder email is already sent" do
      let!(:mandate) { create(:mandate, :freyr_with_data, token_generated_at: started_migration_before - 5.hours) }
      let!(:document) { create(:document, documentable: mandate, document_type: DocumentType.n26_migration_reminder) }

      it "returns entity with aggregated data" do
        customers = repo.customers_to_send_reminder(started_migration_before, reminder_document_type)

        expect(customers.size).to be_zero
      end
    end
  end

  describe "#update_migration_state" do
    let(:state) { "email_verified" }

    it "returns customer entity with updated state" do
      customer = repo.update_migration_state(mandate.id, state)

      expect(customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
      expect(customer.migration_state).to eq(state)
    end
  end

  describe "#update_email" do
    let(:new_email) { Faker::Internet.email }

    it "returns true and updates email" do
      customer = repo.find(mandate.id)

      expect(repo.update_email(customer, new_email)).to be_truthy
      expect(mandate.user.reload.email).to eq new_email
    end
  end

  describe "#customers_without_phone_number" do
    let!(:mandate_with_number) do
      create(:mandate, state: state, owner_ident: owner_ident, info: {}).tap do |mandate|
        create(:user, mandate: mandate)
        create(:phone, mandate: mandate, primary: true, verified_at: DateTime.now)
      end
    end

    it "returns the correct number of mandates without number" do
      mandate

      expect(repo.customers_without_phone_number).to eq(1)
    end
  end

  describe "#customer_ids_already_imported" do
    let!(:mandate) { create(:mandate, info: { freyr_imported: true }) }
    let!(:not_imported_mandate) { create(:mandate, info: {}) }

    it "returns ids that are already marked as fryer imported" do
      ids = repo.customer_ids_already_imported([mandate.id])

      expect(ids).to eq [mandate.id]
    end
  end

  describe "#mark_as_imported" do
    let(:mandate) { create(:mandate, state: state, owner_ident: owner_ident, info: {}) }

    it "returns true and marks customer as imported" do
      customer = repo.find(mandate.id)

      expect(repo.mark_as_imported(customer)).to be_truthy
      expect(mandate.reload.info["freyr_imported"]).to be_truthy
    end
  end

  describe "#save_phone_number!" do
    let(:mandate) { create(:mandate, state: state, owner_ident: owner_ident, info: {}) }
    let(:phone_number) { "+49#{ClarkFaker::PhoneNumber.phone_number}" }

    context "when the phone number doesn't exist in db" do
      it "creates the phone" do
        expect {
          repo.save_phone_number!(mandate.id, phone_number)
        }.to change(::Phone, :count).by(1)

        expect(mandate.phones.first.number).to eq(phone_number)
        expect(mandate.phones.first.primary).to be_truthy
        expect(mandate.phones.first.verified_at).not_to be_nil
      end
    end

    context "when the phone number exists in db" do
      let(:phone_entity) {
        create(:phone, mandate_id: mandate.id, number: phone_number, verified_at: nil, primary: false)
      }

      it "updates the phone" do
        repo.save_phone_number!(mandate.id, phone_entity.number)

        expect(mandate.phones.first.primary).to be_truthy
        expect(mandate.phones.first.verified_at).not_to be_nil
      end
    end
  end
end
