# frozen_string_literal: true

require "rails_helper"
require "support/api_schema_matcher"
require "ostruct"

RSpec.describe ClarkAPI::V2::App::Register, :integration do
  include ApiSchemaMatcher

  context "POST /api/app/register" do
    before { allow(Rails.logger).to receive(:info) }

    context "validation" do
      it "returns 400 with errors when user[email] is missing" do
        json_post_v2 "/api/app/register", user: {password: Settings.seeds.default_password},
                                          mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.email).to be_present
      end

      it "returns 400 with errors when user[password] is missing" do
        json_post_v2 "/api/app/register", user: {email: "theo.tester@clark.de"},
                                          mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.password).to be_present
      end

      it "returns 400 with errors when user[email] is already in use" do
        old_user = create(:user)
        json_post_v2 "/api/app/register",
                     user: {email: old_user.email, password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.email).to be_present
      end

      it "returns 400 with errors when user[password] is too short" do
        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: "Test1"},
                     mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.password).to be_present
      end

      it "returns 400 with errors when user[password] is not complex enough" do
        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: "testtest"},
                     mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.password)
          .to include("#{User.human_attribute_name(:password)} " \
                      "#{I18n.t('activerecord.errors.models.user.password_complexity')}")
      end

      it "should not fail if unknown attribute is defined in mandate" do
        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo", foo: "quatsch"}

        expect(response.status).to eq(201)
        expect(json_response.errors).to be_blank
        expect(json_response.user).to be_present
        expect(json_response.user.mandate).to be_present
        expect(json_response.user.mandate.first_name).to eq("Theo")
        expect(json_response.user.id).to eq(User.last.id)
      end

      it "should return 400 with error user[email] is already in use " \
         "when ActiveRecord::RecordNotUnique is thrown" do
        allow_any_instance_of(User).to receive(:save)
          .and_raise(ActiveRecord::RecordNotUnique.new("something went wrong"))

        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo"}

        expect(response.status).to eq(400)
        expect(json_response.errors.user.email).to be_present
      end

      context "when user[email] is invalid" do
        it "returns 400 with errors" do
          json_post_v2 "/api/app/register",
                       user: { email: "some-invalid#email$&", password: Settings.seeds.default_password },
                       mandate: { first_name: "Theo" }

          expect(response.status).to eq(400)
          expect(json_response.errors.user.email).to be_present
        end

        it "returns 400 with errors (dot in the end)" do
          json_post_v2 "/api/app/register",
                       user: { email: "some-invalid@clark.", password: Settings.seeds.default_password },
                       mandate: { first_name: "Theo" }

          expect(response.status).to eq(400)
          expect(json_response.errors.user.email).to be_present
        end
      end
    end

    it "returns 201 and the serialized user when the user registered" do
      json_post_v2 "/api/app/register",
                   user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                   mandate: {first_name: "Theo"}

      expect(response.status).to eq(201)
      expect(json_response.errors).to be_blank
      expect(json_response.user).to be_present
      expect(json_response.user.mandate).to be_present
      expect(json_response.user.mandate.first_name).to eq("Theo")
      expect(json_response.user.id).to eq(User.last.id)
      expect(Rails.logger).to have_received(:info).with("User #{json_response.user.email} created")
    end

    it "does not send out the confirmation mail when the user registered" do
      # NOTE: https://github.com/plataformatec/devise/blob/4-1-stable/lib/devise/models/confirmable.rb#L48
      #       sends the confirmation email in an after_commit callback.
      #       For making this test pass transaction strategy was disabled by `js: true` annotation.
      expect {
        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo"}
      }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "creates user and mandate when the user registered with adjust" do
      expect {
        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo"}, adjust: {"id" => 1, "text" => {"bla" => "blub"}},
                     installation_id: "abc123"
      }.to change(User, :count).by(1).and change(Mandate, :count).by(1)

      expect(User.last.adjust["id"]).to eq(1)
      expect(User.last.adjust["text"]["bla"]).to eq("blub")
      expect(User.last.installation_id).to eq("abc123")
    end

    it "creates user and mandate when the user registered" do
      expect {
        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo"}
      }.to change(User, :count).by(1).and change(Mandate, :count).by(1)
    end

    it "creates user and mandate even if the mandate is empty when the user registered" do
      expect {
        json_post_v2 "/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {}
      }.to change(User, :count).by(1).and change(Mandate, :count).by(1)
    end

    it "signs the user in when the user registered" do
      json_post_v2 "/api/app/register",
                   user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                   mandate: {first_name: "Theo"}

      created_user_id = json_response.user.id

      expect(@integration_session.request.env["warden"].user(:user).id).to eq(created_user_id)
    end

    it "removes the lead from the session when the user registers" do
      login_as create(:device_lead), scope: :lead

      json_post_v2 "/api/app/register",
                   user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                   mandate: {first_name: "Theo"}

      expect(@integration_session.request.env["warden"].user(:lead)).to be_nil
    end

    it "keeps the mandate of the lead when registering and move it to the new user" do
      lead    = create(:device_lead, email: "theo.tester@clark.de")
      mandate = create(:signed_unconfirmed_mandate, user: nil, lead: lead)

      login_as mandate.lead, scope: :lead

      expect {
        json_post_v2("/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo"})
      }.to change(User, :count).by(1).and change(Mandate, :count).by(0).and change(Lead, :count).by(-1)

      mandate.reload

      expect(mandate.lead).to be_nil
      expect(mandate.user).to be_present
      expect(mandate.user.id).to eq(json_response.user.id)
    end

    it "it creates a mandate if no lead is given" do
      expect {
        json_post_v2("/api/app/register",
                     user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo", last_name: "Tentakel"})
      }.to change(User, :count).by(1).and change(Mandate, :count).by(1)

      user = User.find_by(id: json_response.user.id)

      expect(user.mandate).to be_present
      expect(user.mandate.first_name).to eq("Theo")
      expect(user.mandate.last_name).to eq("Tentakel")
      expect(user.mandate).to be_in_creation
    end

    it "removes the lead from the session when the user registers" do
      login_as create(:device_lead), scope: :lead

      json_post_v2 "/api/app/register",
                   user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                   mandate: {first_name: "Theo"}

      expect(@integration_session.request.env["warden"].user(:lead)).to be_nil
    end

    it 'accepts the parameter "gps_adid"' do
      expected_id = "XYZ987"

      json_post_v2 "/api/app/register",
                   user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                   mandate: {},
                   gps_adid: expected_id

      expect(User.last).to have_advertiser_id("id" => expected_id, "type" => "gps_adid")
    end

    it 'accepts the parameter "idfa"' do
      expected_id = "XYZ987"

      json_post_v2 "/api/app/register",
                   user: {email: "theo.tester@clark.de", password: Settings.seeds.default_password},
                   mandate: {},
                   idfa: expected_id

      expect(User.last).to have_advertiser_id("id" => expected_id, "type" => "idfa")
    end

    context "adjust" do
      it "should migrate the lead's source data" do
        expected_network    = "partner_token"
        source_data         = {"adjust" => {"network" => expected_network}}
        email               = "theo.tester@clark.de"
        lead = create(:device_lead, email: email, source_data: source_data)
        expect(lead.email).not_to be_blank

        login_as lead, scope: :lead

        json_post_v2 "/api/app/register",
                     user: {email: lead.email, password: Settings.seeds.default_password},
                     mandate: {first_name: "Theo"}

        user = User.last
        expect(user.adjust["network"]).to eq(expected_network)
      end
    end

    context "sovendus traffic" do
      let(:sovendus_request_token) { "123456" }

      it "calls sovendus APIs if mandate source is sovendus and has a request token" do
        source_data = { "adjust" => { "network" => OutboundChannels::Sovendus::SOVENDUS_MANDATE_SOURCE } }
        email = "clark.kent@clark.de"
        lead = create(:device_lead, email: email, source_data: source_data)
        mandate = lead.mandate
        mandate.info[OutboundChannels::Sovendus::SOVENDUS_TOKEN_ATTR_NAME] = sovendus_request_token
        mandate.save
        login_as lead, scope: :lead

        expect_any_instance_of(OutboundChannels::Sovendus).to receive(:send_sovendus_call)
        json_post_v2 "/api/app/register",
                     user: { email: lead.email, password: Settings.seeds.default_password },
                     mandate: { first_name: "Clark" }
      end

      it "doesn't call sovendus APIs if mandate source is not sovendus" do
        source_data = { "adjust" => { "network" => "organic" } }
        email = "clark.kent@clark.de"
        lead = create(:device_lead, email: email, source_data: source_data)
        login_as lead, scope: :lead

        expect_any_instance_of(OutboundChannels::Sovendus).not_to receive(:send_sovendus_call)
        json_post_v2 "/api/app/register",
                     user: { email: lead.email, password: Settings.seeds.default_password },
                     mandate: { first_name: "Clark" }
      end
    end
  end
end
