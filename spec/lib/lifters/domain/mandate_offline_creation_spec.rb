# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MandateOfflineCreation do
  describe "create_without_confirmation" do
    let(:asset) { Rack::Test::UploadedFile.new Rails.root.join("spec", "support", "assets", "mandate.pdf") }
    let(:params) do
      {
        first_name: "Foo",
        last_name: "Bar",
        birthdate: "01/01/1990",
        gender: "male",
        street: "Goethestr.",
        house_number: "10",
        zipcode: "60313",
        city: "Frankfurt",
        user: {
          email: "test@clark.de",
          password: "Test1234",
          password_confirmation: "Test1234"
        },
        transfer_data_to_bank: "true",
        reference_id: "11",
        phone: "+49#{ClarkFaker::PhoneNumber.phone_number}",
        country_code: "DE",
        document: { asset: asset },
        addition_to_address: "Addition Test"
      }
    end

    context "with valid parameters" do
      let(:mandate) { described_class.new(params).without_confirmation }

      it "creates an accepted mandate" do
        expect(mandate).to be_accepted
      end

      it "creates a user" do
        expect(mandate.user).to be_persisted
      end

      it "creates an address" do
        expect(mandate.active_address).to be_persisted
        expect(mandate.active_address.accepted).to  eq true
      end

      it "creates a phone" do
        expect(mandate.phone).to eq params[:phone]
      end

      it "creates a mandate document" do
        expect(mandate.document).to be_persisted
        expect(mandate.document.document_type).to eq DocumentType.mandate_document
      end
    end

    context "when tos_accepted is nil" do
      let(:mandate) { described_class.new(params).without_confirmation }

      it "sets tos_accepted to true", :clark_context do
        expect(mandate.tos_accepted).to eq(true)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {first_name: "Foo", last_name: "Bar", birthdate: "01/01/1990", gender: "male", street: "Goethestr.",
         house_number: "10", zipcode: "60313", city: "Frankfurt", user: {email: "", password: "", password_confirmation: ""},
         transfer_data_to_bank: "true", reference_id: "1", phone: "+491234567890", country_code: "DE", document: {asset: ""}}
      end

      let(:mandate) { described_class.new(invalid_params).without_confirmation }

      it "does not create an accepted mandate" do
        expect(mandate).not_to be_persisted
      end

      it "has errors" do
        expect(mandate.errors).not_to be_empty
      end
    end

    context "with invalid addresses" do
      let(:invalid_params) do
        {first_name: "Foo", last_name: "Bar", birthdate: "01/01/1990", gender: "male", street: "Goethestr.",
         house_number: nil, zipcode: "60313", city: "Frankfurt",
         user: {email: "test@clark.de", password: "Test1234", password_confirmation: "Test1234"},
         transfer_data_to_bank: "true", reference_id: "11", phone: "+491234567890", country_code: "DE",
         document: {asset: asset}}
      end

      let(:mandate) { described_class.new(invalid_params).without_confirmation }

      it "does not create an accepted mandate" do
        expect(mandate).not_to be_persisted
      end
    end
  end
end
