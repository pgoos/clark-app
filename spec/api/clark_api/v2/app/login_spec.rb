# frozen_string_literal: true

require "rails_helper"
require "support/api_schema_matcher"
require "ostruct"

RSpec.describe ClarkAPI::V2::App::Login, :integration do
  include ApiSchemaMatcher

  context "POST /api/app/login" do
    let!(:user) do
      create(:user, password: Settings.seeds.default_password, mandate: create(:mandate))
    end

    context "validations" do
      it "returns 400 with errors when user[email] is missing" do
        json_post_v2 "/api/app/login", user: {password: Settings.seeds.default_password},
                                       mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.email).to be_present
      end

      it "returns 400 with errors when user[password] is missing" do
        json_post_v2 "/api/app/login", user: {email: "theo.tester@clark.de"},
                                       mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.password).to be_present
      end
    end

    it "returns 401 with errors on user[email] and user[password] if the email is not found" do
      json_post_v2 "/api/app/login",
                   user: {email: "not-existing-email@clark.de", password: Settings.seeds.default_password}

      expect(response.status).to eq(401)
      expect(json_response.errors.user.email)
        .to eq([I18n.t("api.errors.login.invalid_credentials")])
    end

    it "returns 401 with errors on user[email] and user[password] if the password is wrong" do
      json_post_v2 "/api/app/login", user: {email: user.email, password: "totally-wrong-password"}

      expect(response.status).to eq(401)
      expect(json_response.errors.user.email)
        .to eq([I18n.t("api.errors.login.invalid_credentials")])
    end

    it "returns 401 with errors on acquired by partner user credentials if the password is wrong" do
      partner_user = create(
        :user,
        password: Settings.seeds.default_password,
        mandate: create(:mandate, owner_ident: "partner_ident")
      )

      json_post_v2 "/api/app/login",
                   user: {email: partner_user.email, password: "totally-wrong-password"}

      expect(response.status).to eq(401)
      expect(json_response.errors.user.email)
        .to eq([I18n.t("api.errors.login.partner_invalid_credentials")])
    end

    it "returns 200 and the serialized user when the login succeeds" do
      json_post_v2 "/api/app/login", user: {email: user.email, password: Settings.seeds.default_password}

      expect(response.status).to eq(200)
      expect(json_response.errors).to be_blank
      expect(json_response.user).to be_present
      expect(json_response.user.id).to eq(user.id)
    end

    context "when previous visit exists" do
      let(:ahoy_visit) { "c1b6324a-bcb4-4ce8-b44c-88493f4d912a" }
      let(:ahoy_visitor) { "668337f0-8707-426b-a797-adcb5348640e" }
      let(:ahoy_cookies) do
        {"HTTP_COOKIE" => "ahoy_visit=#{ahoy_visit}; ahoy_visitor=#{ahoy_visitor};"}
      end
      let(:tracking_visit) { create(:tracking_visit, id: ahoy_visit, visitor_id: ahoy_visitor) }

      before do
        allow(Raven).to receive(:capture_exception)
        tracking_visit
        json_post_v2("/api/app/login", {
                       user: {
                         email: user.email, password: Settings.seeds.default_password
                       }
                     }, ahoy_cookies)
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(Raven).not_to receive(:capture_exception) }
    end

    it "signs in the user when everything is correct" do
      json_post_v2 "/api/app/login", user: {email: user.email, password: Settings.seeds.default_password}
      expect(@integration_session.request.env["warden"].user(:user)).to eq(user)
    end

    it "removes the lead from the session when the user logs in" do
      login_as create(:device_lead), scope: :lead

      json_post_v2 "/api/app/login", user: {email: user.email, password: Settings.seeds.default_password}

      expect(@integration_session.request.env["warden"].user(:lead)).to be_nil
    end

    it "should append gps_adids" do
      expected_id = "XYZ987"
      json_post_v2 "/api/app/login", user: {email: user.email, password: Settings.seeds.default_password},
                                     gps_adid: expected_id

      expect(response.status).to eq(200)
      expect(User.last).to have_advertiser_id("id" => expected_id, "type" => "gps_adid")
    end

    it "should append idfas" do
      expected_id = "XYZ987"
      json_post_v2 "/api/app/login", user: {email: user.email, password: Settings.seeds.default_password},
                                     idfa: expected_id

      expect(response.status).to eq(200)
      expect(User.last).to have_advertiser_id("id" => expected_id, "type" => "idfa")
    end
  end
end
