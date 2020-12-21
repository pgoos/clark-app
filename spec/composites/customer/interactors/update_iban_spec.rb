# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Interactors::UpdateIBAN do
  subject(:update_iban) do
    described_class.new(
      profile_repo: profile_repo,
      validator: validator
    )
  end

  let(:profile_repo)       { double :repo }
  let(:validator)          { double :validator, call: validator_response }
  let(:validator_response) { double(:response, failure?: false) }

  let(:customer_id)        { 1984 }
  let(:customer)           { double :customer }
  let(:iban)               { "NL07ABNA7229237580" }
  let(:params)             { { iban: iban, consent: true } }
  let(:updated_profile)    { double :updated_customer, customer_id: customer_id }

  context "when params are valid and customer exists" do
    it "update customer IBAN and returns updated profile" do
      expect(profile_repo).to  receive(:update!).with(customer_id, { iban: iban })
      expect(profile_repo).to  receive(:find_by).with(customer_id: customer_id).and_return(updated_profile)

      result = update_iban.(customer_id, params)
      expect(result.ok?).to be(true)
      result.on_success { |value| expect(value).to eq(updated_profile) }
    end
  end

  context "when params are invalid" do
    shared_examples "returns Interactors::Errors::ValidationError" do
      it do
        result = update_iban.(customer_id, params)
        expect(result.error?).to be(true)
        result.on_failure { |error| expect(error).to be_a(Interactors::Errors::ValidationError) }
        result.on_failure { |error| expect(error.errors).to eq(errors_hash) }
      end
    end

    context "when IBAN is invalid" do
      let(:errors)             { double(:errors, to_h: errors_hash) }
      let(:errors_hash)        { { error: "something went wrong" } }
      let(:validator_response) { double(:response, failure?: true, errors: errors) }

      it_behaves_like "returns Interactors::Errors::ValidationError"
    end

    context "when consent is not true" do
      let(:errors_hash) { { consent: [I18n.t("checkout.validation.consent")] } }
      let(:params)      { { iban: iban, consent: nil } }

      it_behaves_like "returns Interactors::Errors::ValidationError"
    end
  end

  context "when customer does not exist" do
    let(:exception) { Utils::Repository::Errors::NotFoundError }

    it "returns Interactors::Errors::NotFoundError" do
      expect(profile_repo).to receive(:update!).with(customer_id, { iban: iban }).and_raise(exception)
      result = update_iban.(customer_id, params)
      expect(result.error?).to be(true)
      result.on_failure { |error| expect(error).to be_a(Interactors::Errors::NotFoundError) }
      result.on_failure { |error| expect(error.message).to eq("Customer not found") }
    end
  end

  context "when profile repo throws Utils::Repository::Errors::ValidationError" do
    let(:exception)      { Utils::Repository::Errors::ValidationError }
    let(:error_msg)      { "Code red" }
    let(:expected_error) { { iban: [error_msg] } }

    it "handles exception and returns Interactors::Errors::NotFoundError" do
      allow(profile_repo).to  receive(:update!).and_raise(exception, error_msg)

      result = update_iban.(customer_id, params)
      expect(result.error?).to be(true)
      result.on_failure { |error| expect(error).to be_a(Interactors::Errors::ValidationError) }
      result.on_failure { |error| expect(error.errors).to eq(expected_error) }
    end
  end
end
