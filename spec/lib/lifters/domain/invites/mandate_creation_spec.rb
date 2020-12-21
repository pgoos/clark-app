# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Invites::MandateCreation, :integration do
  subject { described_class.new(params) }

  let(:mandate) { subject.call }

  describe "#call" do
    let(:malburg) { create(:partner, :active, ident: Domain::Owners::MALBURG_IDENT) }
    let(:params) do
      { first_name: "Foo", last_name: "Bar", birthdate: "01/01/1990", gender: "male", street: street,
        house_number: house_number, zipcode: zipcode, city: city, phone: "+491234567890", country_code: country_code,
        reference_id: "100000", owner_ident: malburg.ident, addition_to_address: addition_to_address,
        lead: Lead.new(email: "test@clark.de") }
    end
    let(:street) { "Goethestr." }
    let(:house_number) { "10" }
    let(:zipcode) { "60313" }
    let(:city) { "Frankfurt" }
    let(:country_code) { "DE" }
    let(:addition_to_address) { "Addition Test" }

    context "when valid attributes" do
      let(:source) do
        {"anonymous_lead" => true, "adjust" => {"network" => "Malburg", "campaign" => "Call"}}
      end
      let(:steps) do
        {"wizard_steps" => %w[targeting], "transfer_data_to_bank" => false, "reference_id" => "100000"}
      end

      it "has the correct attributes" do
        expect(mandate).to be_persisted
        expect(mandate.lead).to be_persisted
        expect(mandate.info).to eq steps
        expect(mandate.lead.source_data).to eq source
        expect(mandate.phones).not_to be_nil
        expect(mandate).to be_in_creation
        expect(mandate.addresses.count).to eq(1)
        active_address = mandate.active_address
        expect(active_address.street).to eq(street)
        expect(active_address.house_number).to eq(house_number)
        expect(active_address.zipcode).to eq(zipcode)
        expect(active_address.city).to eq(city)
        expect(active_address.country_code).to eq(country_code)
        expect(active_address.addition_to_address).to eq(addition_to_address)
      end

      context "with multiple addresses switched on" do
        before do
          allow(Features).to receive(:active?).with(any_args).and_return(false)
          allow(Features).to receive(:active?).with(Features::MULTIPLE_ADDRESSES).and_return(true)
        end

        after do
          allow(Features).to receive(:active?).with(any_args).and_call_original
        end

        it "has the correct attributes" do
          expect(mandate).to be_persisted
          expect(mandate.lead).to be_persisted
          expect(mandate.info).to eq steps
          expect(mandate).to be_in_creation
          expect(mandate.lead.source_data).to eq source
          expect(mandate.phones).not_to be_nil
          expect(mandate.addresses.count).to eq(1)
          active_address = mandate.active_address

          mandate.reload

          expect(active_address).to eq(mandate.active_address)
          expect(active_address).to be_active
          expect(active_address).to be_accepted
          expect(active_address.street).to eq(street)
          expect(active_address.house_number).to eq(house_number)
          expect(active_address.zipcode).to eq(zipcode)
          expect(active_address.city).to eq(city)
          expect(active_address.country_code).to eq(country_code)
          expect(active_address.addition_to_address).to eq(addition_to_address)
        end
      end
    end

    context "when creating Communikom user" do
      subject { described_class.new(params) }

      let(:communikom) { create(:partner, :active, ident: Domain::Owners::COMMUNIKOM_IDENT) }
      let(:mandate_communikom) { subject.call }
      let(:params) do
        {first_name: "Foo", last_name: "Bar", birthdate: "01/01/1990", gender: "male", street: street,
         house_number: house_number, zipcode: zipcode, city: city, phone: "+491234567890", country_code: country_code,
         reference_id: "100000", owner_ident: communikom.ident, lead: Lead.new(email: "test@clark.de")}
      end

      let(:source) do
        {"anonymous_lead" => true, "adjust" => {"network" => "Communikom"}}
      end

      it "has creates a lead with network set to communikom" do
        expect(mandate_communikom).to be_persisted
        expect(mandate_communikom.lead).to be_persisted
        expect(mandate_communikom.lead.source_data).to eq source
      end
    end

    context "when e-mail already registered" do
      before do
        create(:lead, email: "test@clark.de")
      end

      it { expect(mandate).not_to be_persisted }
      it { expect(mandate.lead).not_to be_persisted }
      it { expect(mandate.errors.keys).to eq [:email] }
    end

    context "when valid attributes with owner ident as clark" do
      let(:clark_source) { {"anonymous_lead" => true, "adjust" => {"network" => "fb-malburg"}} }
      let(:clark) { "clark" }

      before do
        params[:owner_ident] = clark
      end

      it { expect(mandate).to be_persisted }
      it { expect(mandate.lead.source_data).to eq clark_source }
      it { expect(mandate.owner_ident).to eq clark }
    end
  end
end
