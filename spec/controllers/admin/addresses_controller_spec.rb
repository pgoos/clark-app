# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AddressesController, :integration, type: :controller do
  let(:admin)   { create(:super_admin) }
  let(:mandate) { create :mandate, :accepted, products: [create(:product)] }
  let(:mail) { n_double("mail") }

  before do
    sign_in(admin)
    allow_any_instance_of(MandateMailer)
      .to receive(:change_address_notification)
      .with(any_args)
      .and_return(mail)
    allow(mail).to receive(:deliver_now)
  end

  after do
    allow_any_instance_of(MandateMailer)
      .to receive(:change_address_notification)
      .with(any_args)
      .and_call_original
  end

  describe "POST create" do
    let(:address) { Address.where(mandate: mandate).last }

    let(:base_params) do
      {
        street: "NEW STREET",
        house_number: "1",
        city: "NEW CITY",
        zipcode: "12345",
        apartment_size: "100",
        active_at: Time.zone.today
      }
    end

    before do
      allow(Settings).to(
        receive_message_chain("addition_to_address.expose")
          .and_return(true)
      )
      allow(Settings).to(
        receive_message_chain("addition_to_address.validates_presence")
          .and_return(setting_enabled)
      )
      post :create, params: {
        locale: :de,
        mandate_id: mandate.id,
        address: address_params,
        send_notification: "1"
      }
    end

    context "when addition_to_address validation is disabled" do
      let(:setting_enabled) { false }

      let(:address_params) { base_params }

      it "creates a new customer's address" do
        expect(response).to redirect_to admin_mandate_addresses_path(mandate)
        expect(address).to be_accepted
        expect(address).to be_active
        expect(address).to be_insurers_notified
        expect(address.street).to eq "New Street"
      end
    end

    context "when addition_to_address validation is enabled" do
      let(:setting_enabled) { true }

      let(:address_params) do
        base_params.merge(addition_to_address: "Nadya Court")
      end

      it "creates a new customer's address" do
        expect(response).to redirect_to admin_mandate_addresses_path(mandate)
        expect(address).to be_accepted
        expect(address).to be_active
        expect(address).to be_insurers_notified
        expect(address.street).to eq "New Street"
        expect(address.addition_to_address).to eq "Nadya Court"
      end
    end
  end

  describe "PATCH update" do
    let(:address) do
      create :address, mandate: mandate, accepted: false, active: false, insurers_notified: false
    end

    it "updates customer's address" do
      patch :update, params: {
        locale: :de,
        mandate_id: mandate.id,
        id: address.id,
        address: {street: "NEW STREET", active_at: Time.zone.today},
        send_notification: "1"
      }
      expect(response).to redirect_to admin_mandate_addresses_path(mandate)
      expect(address.reload).to be_accepted
      expect(address).to be_active
      expect(address).to be_insurers_notified
    end
  end
end
