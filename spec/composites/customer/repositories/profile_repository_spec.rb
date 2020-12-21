# frozen_string_literal: true

require "rails_helper"
require "composites/customer/repositories/profile_repository"

RSpec.describe Customer::Repositories::ProfileRepository, :integration do
  subject(:repo) { described_class.new }

  # NOTE Need to set phone since it's not set by default on mandate's factory
  let(:mandate) { create(:mandate, phone: "+491111111111") }

  describe "#find_by" do
    it "returns entity with aggregated data" do
      profile = repo.find_by(customer_id: mandate.id)

      expect(profile).to be_kind_of Customer::Entities::Profile
      expect(profile.customer_id).to eq mandate.id
      expect(profile.first_name).to eq mandate.first_name
      expect(profile.last_name).to eq mandate.last_name
      expect(profile.birthdate).to eq mandate.birthdate
      expect(profile.gender).to eq mandate.gender
      expect(profile.phone_number).to eq mandate.phone
      expect(profile.phone_verified).to eq mandate.primary_phone_verified
      expect(profile.iban_for_display).to eq mandate.iban_for_display
      expect(profile.address).to be_kind_of Customer::Entities::Address
      expect(profile.address.customer_id).to eq mandate.id
    end

    context "when profile does not exist" do
      it "returns nil" do
        expect(repo.find_by(customer_id: 999)).to be_nil
      end
    end

    context "when address does not exist" do
      it "returns nil" do
        # NOTE: need to remove address since it's default trait in mandates factory
        mandate.addresses.destroy_all
        profile = repo.find_by(customer_id: mandate.id)

        expect(profile).to be_kind_of Customer::Entities::Profile
        expect(profile.address).to be_nil
      end
    end
  end

  describe "#update!" do
    let(:first_name)    { "Hero" }
    let(:last_name)     { "Alam" }
    let(:street)        { "Tongi" }
    let(:house_number)  { "123" }
    let(:city)          { "Frankfurt" }
    let(:zipcode)       { "61390" }
    let(:phone_number)  { "+49#{ClarkFaker::PhoneNumber.phone_number}" }
    let(:iban)          { "DE89 3704 0044 0532 0130 00" }

    context "fails on validation" do
      let(:phone_number) { "123" }

      it do
        expect { repo.update!(mandate.id, phone_number: phone_number) }
          .to raise_error(Utils::Repository::Errors::ValidationError)
      end
    end

    context "updates the mandate" do
      it do
        repo.update!(
          mandate.id,
          first_name: first_name,
          last_name: last_name,
          phone_number: phone_number,
          iban: iban,
          street: street,
          house_number: house_number,
          city: city,
          zipcode: zipcode
        )

        mandate.reload

        expect(mandate.first_name).to eq first_name
        expect(mandate.last_name).to eq last_name
        expect(mandate.phone).to eq phone_number
        expect(mandate.send(:iban)).to eq iban.gsub(" ", "")

        address = mandate.active_address

        expect(address.house_number).to eq house_number
        expect(address.street).to eq street
        expect(address.city).to eq city
        expect(address.zipcode).to eq zipcode
      end
    end

    context "mandate with address" do
      let(:mandate) { create(:mandate, :with_address) }
      let(:address) { mandate.active_address }

      it "does not save empty address" do
        repo.update!(
          mandate.id,
          first_name: first_name,
          last_name: last_name
        )

        mandate.reload

        expect(mandate.first_name).to eq first_name
        expect(mandate.last_name).to eq last_name

        expect(address.house_number).not_to be_nil
        expect(address.street).not_to be_nil
        expect(address.city).not_to be_nil
        expect(address.zipcode).not_to be_nil
      end
    end
  end
end
