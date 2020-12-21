# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SessionsController, :integration, type: :controller do
  let!(:role) { create(:role, :super_admin) }
  let(:pw) { Settings.seeds.default_password }
  let!(:admin) { create(:super_admin, password: pw) }
  let(:credentials) { {email: admin.email, pw: pw} }
  let(:login_params) do
    {admin: {email: credentials[:email], password: credentials[:pw]}, locale: "de"}
  end
  let(:login) { -> { post :create, params: login_params } }

  before do
    request.env["devise.mapping"] = Devise.mappings[:admin]
    allow(Settings).to receive_message_chain(:devise, :maximum_attempts) { 10 }
    allow(Settings).to receive_message_chain(:devise, :unlock_in_mins)   { 60 }
  end

  context "when logging in as active admin" do
    it "should allow to log in" do
      login.()
      expect(warden.user(:admin)).to eq(admin)
    end

    it "should not allow to login, if the email does not exist" do
      credentials[:email] = "wrong@clark.de"
      login.()
      expect(warden.user(:admin)).to be_nil
    end

    it "should not allow to login, if the pw is wrong" do
      credentials[:pw] = "Wrong1234"
      login.()
      expect(warden.user(:admin)).to be_nil
    end

    it "should not allow to login, if the pw is empty" do
      credentials[:pw] = ""
      login.()
      expect(warden.user(:admin)).to be_nil
    end
  end

  context "when logging in as deactivated admin" do
    before do
      admin.deactivate!
    end

    it "should not allow to login" do
      login.()
      expect(warden.user(:admin)).to be_nil
    end

    it "should not allow to login, if the pw is wrong" do
      credentials[:pw] = "Wrong1234"
      login.()
      expect(warden.user(:admin)).to be_nil
    end

    it "should not allow to login, if the pw is empty" do
      credentials[:pw] = ""
      login.()
      expect(warden.user(:admin)).to be_nil
    end
  end

  context "when logging in with an initial password" do
    before do
      admin.update!(password_expires_at: password_expires_at)
      login.()
    end

    context "when password expired" do
      let(:password_expires_at) { Time.zone.now - 1.day }

      it "doesn't allow to login" do
        expect(warden.user(:admin)).to be_nil
      end
    end

    context "when password isn't expired yet" do
      let(:password_expires_at) do
        Time.zone.now + 14.days
      end

      it "allows to login" do
        expect(warden.user(:admin)).to eq(admin)
      end
    end
  end

  context "GET #destroy" do
    before do
      sign_in(admin)
    end

    it "updated the business event for the log-out" do
      expect(BusinessEvent).to receive(:audit).with(admin, "log-out")
      get :destroy, params: {
        locale: :de
      }
    end
  end
end
