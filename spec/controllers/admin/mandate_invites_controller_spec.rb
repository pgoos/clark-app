# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MandateInvitesController, :integration, type: :controller do
  let(:mandate) { create(:mandate, state: :accepted) }
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/mandate_invites")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET /new" do
    it { expect(response).to be_ok }
  end

  describe "POST /mail" do
    let(:invite_mailer) { instance_double(Domain::Mails::Invite, call: true) }

    context "with valid attributes" do
      before do
        allow(Domain::Mails::Invite).to receive(:new).with(mandate, admin).and_return(invite_mailer)

        post :mail, params: {format: :html, locale: :de, id: mandate.id}
      end

      it { expect(invite_mailer).to have_received(:call) }
    end

    context "with invalid attributes" do
      before do
        allow(Domain::Mails::Invite).to receive(:new).with(mandate, admin).and_return(invite_mailer)
        allow(invite_mailer).to receive(:call).and_raise(Domain::Mails::InviteError)

        post :mail, params: {format: :html, locale: :de, id: mandate.id}
      end

      it { is_expected.to set_flash[:alert] }
    end
  end

  describe "POST /sms" do
    let(:sms) { instance_double(Domain::Interactions::Sms, send: "some message") }

    before do
      allow(Domain::Interactions::Sms).to receive(:new).with(mandate, admin).and_return(sms)
      allow(Platform::LeadSessionRestoration).to receive(:create_shortened_url_with_encryption)
        .and_return("this is a link")
    end

    it "sends sms to clark users" do
      post :sms, params: {format: :html, locale: :de, id: mandate.id}
      expect(sms).to have_received(:send)
    end
  end

  describe "POST /create" do
    let(:params) do
      {first_name: "Foo", last_name: "Bar", birthdate: "01/01/1990", gender: "male", street: "Goethestr.",
       house_number: "10", zipcode: "60313", city: "Frankfurt", phone: ClarkFaker::PhoneNumber.phone_number, country_code: "DE",
       reference_id: "1000000", lead_attributes: {email: "test@clark.de"}}
    end

    context "with valid params" do
      before do
        post :create, params: {locale: :de, mandate: params}
      end

      it { is_expected.to set_flash[:notice] }
      it { is_expected.to redirect_to(admin_mandates_path) }
    end

    context "with invalid attributes" do
      before do
        create(:lead, email: "test@clark.de")
        post :create, params: {locale: :de, mandate: params}
      end

      it { is_expected.to set_flash[:alert] }
      it { is_expected.to render_template("new") }
    end
  end
end
