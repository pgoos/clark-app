# frozen_string_literal: true

require "rails_helper"
require "support/api_schema_matcher"
require "ostruct"

include ApiSchemaMatcher

RSpec.describe ClarkAPI::V2::App::Oauth, :integration do
  context "POST /api/app/oauth/:provider" do
    let!(:facebook_email) { Faker::Internet.email }
    let!(:facebook_uid) { rand(10_000..10_000_000).to_s }
    let!(:facebook_token) { SecureRandom.uuid }

    context "provider: Facebook" do
      let!(:koala_mock) { n_double("koala_mock") }

      before do
        allow(Koala::Facebook::API).to receive(:new).and_return(koala_mock)
      end

      context "validation" do
        it "returns 400 with errors when auth[token] is missing" do
          json_post_v2 "/api/app/oauth/facebook", auth: {uid: facebook_uid}

          expect(response.status).to eq(400)
          expect(json_response.errors.auth.token).to be_present
        end

        it "returns 400 with errors when auth[uid] is missing" do
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token}

          expect(response.status).to eq(400)
          expect(json_response.errors.auth.uid).to be_present
        end

        it "returns 400 with errors when provider is invalid" do
          json_post_v2 "/api/app/oauth/provider-we-dont-support", auth: {token: facebook_token, uid: facebook_uid}

          expect(response.status).to eq(400)
          expect(json_response.errors.api.provider).to be_present
        end
      end

      it "returns 401 if the auth token is no longer valid" do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_raise(Koala::Facebook::AuthenticationError.new(400, "some error"))

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        expect(response.status).to eq(401)
        expect(json_response.errors.auth.token).to be_present
      end

      it "returns 401 if we could not talk to facebook" do
        expect(Raven).to receive(:capture_exception).with(Faraday::ConnectionFailed)
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_raise(Faraday::ConnectionFailed.new("something wrong"))

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        expect(response.status).to eq(401)
        expect(json_response.errors.auth.token).to be_present
      end

      it "returns 500 if anything else goes wrong while talking to facebook (notifying Sentry)" do
        expect(Raven).to receive(:capture_exception).with(Koala::Facebook::ClientError)
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_raise(Koala::Facebook::ClientError.new(400, "some response body"))

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        expect(response.status).to eq(500)
      end

      it 'returns 401 if the token user id and sent user id don\'t match' do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => "a-wrong-uid", "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        expect(response.status).to eq(401)
        expect(json_response.errors.auth.uid).to be_present
      end

      it 'returns 406 if the user didn\'t give us access to his email address' do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        expect(response.status).to eq(406)
        expect(json_response.errors.user.email).to be_present
      end

      it "returns 201 and returns the user data" do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        expect(response.status).to eq(201)
        expect(json_response.errors).to be_blank
        expect(json_response.user).to be_present
        expect(json_response.user.mandate).to be_present
        expect(json_response.user.id).to eq(User.last.id)
        expect(json_response.user.email).to eq(facebook_email)
      end

      it "should append gps_adids" do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        expected_id = "XYZ987"
        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}, gps_adid: expected_id

        expect(User.last).to have_advertiser_id("id" => expected_id, "type" => "gps_adid")
      end

      it "should append idfas" do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        expected_id = "XYZ987"
        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}, idfa: expected_id

        expect(User.last).to have_advertiser_id("id" => expected_id, "type" => "idfa")
      end

      it "creates a new user object with a mandate" do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        expect {
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
        }.to change { User.count }.by(1).and change { Mandate.count }.by(1)
      end

      it "adds the facebook identity to the already registered user" do
        user = create(:user, :with_mandate)
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => user.email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        expect {
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
        }.to change { Identity.where(user_id: user.id).count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response.user).to be_present
      end

      it "signs in the user when everything is correct" do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        user = User.find_by(email: facebook_email)
        expect(@integration_session.request.env["warden"].user(:user)).to eq(user)
      end

      it "stores adjust parameters, if given" do
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        expect {
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}, adjust: {"id" => 1, "text" => {"bla" => "blub"}}, installation_id: SecureRandom.uuid
        }.to change { User.count }.by(1).and change { Mandate.count }.by(1)
        expect(User.last.adjust["id"]).to eq(1)
        expect(User.last.adjust["text"]["bla"]).to eq("blub")
      end

      it "does not overwrite adjust parameters, if they are already present" do
        email = facebook_email
        first_name = "Theo"
        last_name = "Tester"
        gender = "male"
        create(:user, email: email, adjust: {"id" => 1, "text" => {"bla" => "blub"}}, mandate: create(:mandate, first_name: first_name, last_name: last_name, gender: gender))
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => email, "bio" => "some bio", "first_name" => first_name, "gender" => gender, "last_name" => last_name, "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
        expect {
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}, adjust: {"wrong" => "adjust params"}, installation_id: SecureRandom.uuid
        }.not_to change { User.count }
        expect(User.last.adjust["id"]).to eq(1)
        expect(User.last.adjust["text"]["bla"]).to eq("blub")
      end

      it "stores the installation id, if given" do
        installation_id = SecureRandom.uuid

        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        expect {
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}, installation_id: installation_id
        }.to change { User.count }.by(1).and change { Mandate.count }.by(1)
        expect(User.last.installation_id).to eq(installation_id)
      end

      it "does not delete an existing installation id" do
        installation_id = SecureRandom.uuid
        email = facebook_email
        first_name = "Theo"
        last_name = "Tester"
        gender = "male"
        create(:user, installation_id: installation_id, email: email, adjust: {"id" => 1, "text" => {"bla" => "blub"}}, mandate: create(:mandate, first_name: first_name, last_name: last_name, gender: gender))
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => email, "bio" => "some bio", "first_name" => first_name, "gender" => gender, "last_name" => last_name, "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
        expect {
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}, adjust: {"wrong" => "adjust params"}, installation_id: ""
        }.not_to change { User.count }
        expect(User.last.installation_id).to eq(installation_id)
      end

      it "does overwrite an existing installation id" do
        old_installation_id = SecureRandom.uuid
        new_installation_id = SecureRandom.uuid
        email = facebook_email
        first_name = "Theo"
        last_name = "Tester"
        gender = "male"
        create(:user, installation_id: old_installation_id, email: email, adjust: {"id" => 1, "text" => {"bla" => "blub"}}, mandate: create(:mandate, first_name: first_name, last_name: last_name, gender: gender))
        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => email, "bio" => "some bio", "first_name" => first_name, "gender" => gender, "last_name" => last_name, "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
        expect {
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}, adjust: {"wrong" => "adjust params"}, installation_id: new_installation_id
        }.not_to change { User.count }
        expect(User.last.installation_id).to eq(new_installation_id)
      end

      context "building mandate from facebook data" do
        it "includes first and last name" do
          expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
          expect(Mandate.last.first_name).to eq("Theo")
          expect(Mandate.last.last_name).to eq("Tester")
        end

        it "includes gender when male" do
          expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
          expect(Mandate.last.gender).to eq("male")
        end

        it "includes gender when female" do
          expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => "thea.tester@test.clark.de", "bio" => "some bio", "first_name" => "Thea", "gender" => "female", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
          expect(Mandate.last.gender).to eq("female")
        end

        it "removes gender when it is something else" do
          expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => "thea.tester@test.clark.de", "bio" => "some bio", "first_name" => "Thea", "gender" => "other", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
          expect(Mandate.last.gender).to be_nil
        end

        it "includes the birthday when we have it" do
          expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("birthday" => "01/23/1980", "id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
          expect(Mandate.last.birthdate.to_date).to eq(Date.new(1980, 1, 23))
        end

        it "does not add the birthday if the user only provides MM/DD" do
          expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("birthday" => "01/23", "id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
          expect(Mandate.last.birthdate).to be_nil
        end

        it "does not add the birthday if the user only provides YYYY" do
          expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("birthday" => "1980", "id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
          expect(Mandate.last.birthdate).to be_nil
        end
      end

      it "converts a lead to user" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        login_as(device_lead, scope: :lead)

        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        # Response should include the correct data
        expect(response.status).to eq(201)
        expect(json_response.errors).to be_blank
        expect(json_response.user).to be_present
        expect(json_response.user.mandate).to be_present
        expect(json_response.user.id).to eq(User.last.id)
        expect(json_response.user.email).to eq(facebook_email)

        user = User.where(id: json_response.user.id).first

        # User should be created
        expect(user.source_data["installation_id"]).to eq(device_lead.installation_id)

        # Mandate should have been moved from lead to user
        expect(user.mandate_id).to eq(device_lead.mandate_id)

        # Device lead should be removed
        expect(Lead.where(id: device_lead.id).count).to eq(0)
      end

      it "removes the lead from the session when the user logs in" do
        login_as create(:device_lead), scope: :lead

        expect(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)

        json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}

        expect(@integration_session.request.env["warden"].user(:lead)).to be_nil
      end

      context "regression: lead -> user conversion via facebook login" do
        before {
          RSpec::Expectations.configuration.warn_about_potential_false_positives = false
        }
        after {
          RSpec::Expectations.configuration.warn_about_potential_false_positives = true
        }

        context "lead with mandate" do
          let!(:lead_mandate) { create(:mandate) }
          let!(:lead) { create(:device_lead, mandate: lead_mandate) }

          before do
            login_as(lead, scope: :lead)
            allow(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          end

          it "converts lead to user when user has no mandate (deleting lead)" do
            user = create(:user, email: facebook_email, mandate: nil)

            expect(DeviceLeadConverter).to receive(:convert_device_lead_to_user).with(lead, user, anything).and_call_original

            # Auth with facebook
            expect {
              json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
            }.to change { Lead.count }.by(-1).and change { Mandate.count }.by(0).and change { User.count }.by(0)

            user.reload

            expect(user.mandate).to eq(lead_mandate)
            expect(lead_mandate.reload_lead).to be_nil
            expect { lead_mandate.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
            expect { lead.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "converts lead to user when user has an empty mandate (deleting user mandate and lead)" do
            user_mandate = create(:mandate, state: "in_creation")
            user = create(:user, email: facebook_email, mandate: user_mandate)

            expect(DeviceLeadConverter).to receive(:convert_device_lead_to_user).with(lead, user, anything).and_call_original

            # Auth with facebook
            expect {
              json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
            }.to change { Lead.count }.by(-1).and change { Mandate.count }.by(-1).and change { User.count }.by(0)

            user.reload

            expect(user.mandate).to eq(lead_mandate)
            expect(lead_mandate.reload_lead).to be_nil

            # lead_mandate should still exist
            expect { lead_mandate.reload }.not_to raise_error(ActiveRecord::RecordNotFound)

            # user_mandate and lead should be deleted
            expect { user_mandate.reload }.to raise_error(ActiveRecord::RecordNotFound)
            expect { lead.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "updates lead to user when user has a created (finished) mandate (deleting lead and lead mandate)" do
            user_mandate = create(:mandate, state: "created")
            user = create(:user, email: facebook_email, mandate: user_mandate)

            expect(DeviceLeadConverter).to receive(:update_user_from_device_lead).with(lead, user).and_call_original

            # Auth with facebook
            expect {
              json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
            }.to change { Lead.count }.by(-1).and change { Mandate.count }.by(-1).and change { User.count }.by(0)

            user.reload

            expect(user.mandate).to eq(user_mandate)

            # user_mandate should still exist
            expect { user_mandate.reload }.not_to raise_error(ActiveRecord::RecordNotFound)

            # lead_mandate and lead should be deleted
            expect { lead_mandate.reload }.to raise_error(ActiveRecord::RecordNotFound)
            expect { lead.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "converts lead to user when user did not exist before" do
            expect(DeviceLeadConverter).to receive(:convert_device_lead_to_user).with(lead, User, anything).and_call_original

            # Auth with facebook
            expect {
              json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
            }.to change { Lead.count }.by(-1).and change { Mandate.count }.by(0).and change { User.count }.by(1)

            user = User.find_by(email: facebook_email)
            expect(user.mandate).to eq(lead_mandate)
            expect(lead_mandate.reload_lead).to be_nil

            # lead_mandate should still exist and lead should be deleted
            expect { lead_mandate.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
            expect { lead.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context "no current_lead present" do
          before do
            allow(koala_mock).to receive(:get_object).with("me", fields: %w[id name email]).and_return("id" => facebook_uid, "email" => facebook_email, "bio" => "some bio", "first_name" => "Theo", "gender" => "male", "last_name" => "Tester", "link" => "https://www.facebook.com/app_scoped_user_id/47110815/", "locale" => "en_US", "name" => "Theo Tester", "timezone" => 1, "updated_time" => 1.day.ago, "verified" => true)
          end

          it "creates a user and a mandate (with the facebook data) when user did not exist before^" do
            expect(DeviceLeadConverter).not_to receive(:update_user_from_device_lead)
            expect(DeviceLeadConverter).not_to receive(:convert_device_lead_to_user)

            expect {
              json_post_v2 "/api/app/oauth/facebook", auth: {token: facebook_token, uid: facebook_uid}
            }.to change { Lead.count }.by(0).and change { Mandate.count }.by(1).and change { User.count }.by(1)
          end
        end
      end
    end

    context "provider: apple" do
      before do
        allow(Net::HTTP).to receive(:get).and_return(apple_auth_keys)
      end

      let(:apple_auth_keys) do
        File.read(Rails.root.join("spec", "fixtures", "apple_auth_keys"))
      end

      let(:jwt) do
        <<~JWT.gsub("\n", "")
          eyJraWQiOiI4NkQ4OEtmIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwb
          GUuY29tIiwiYXVkIjoiZGUuY2xhcmsuaW9zLmlwaG9uZS5jbGFyayIsImV4cCI6MTU5NjE5MDMxMSwia
          WF0IjoxNTk2MTg5NzExLCJzdWIiOiIwMDEwMTguYjNkMzRiMDVlNThhNGYxY2I5OGYwMmQxMTAxNWI5O
          WIuMTQyOCIsImNfaGFzaCI6ImVGbHRiS1ViY2lSalZHRUxQbzhEdGciLCJlbWFpbCI6ImVsdmlpbi5hc
          HBsZS5pZEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6InRydWUiLCJhdXRoX3RpbWUiOjE1OTYxO
          Dk3MTEsIm5vbmNlX3N1cHBvcnRlZCI6dHJ1ZX0.CRC0LPz7qNGQs24mBGrrXmiuzjYoPNs4OB0Ncl_5n
          jhYhQnuQPDugk1sLAoODgneyBUgqOcDe78TDFDCpqb-mMwZrNPzjBcdiirSTCDJaokD0k7QqFw9dJX4m
          7m778bf_VrmJAApZKERoQ5jlJ0K40BME397T4jjFNcwLyw5PK9Hc5-da_5xMD9-SVQtrJ2UqFAgxt2u0
          eLRhc9Lbddag0r87h04_IcviIDN1yUZO5kzgX0AR3v25CNGOG61qR60NLf7CJ5SP81tnXMYkcRPbmY13
          dI4Dcn6FOYXu2NG2wjT7WRvWgcDqOK97IBn3zeu_VqtJHH3YH7cSXQ_x8uC4A
        JWT
      end
      let(:jwt_auth_time) { 1_596_189_711 } # encoded in jwt token

      let!(:auth) do
        {
          user: {
            email:      Faker::Internet.email,
            firstName:  Faker::Name.first_name,
            lastName:   Faker::Name.last_name
          },
          token:        jwt,
          uid:          "001018.b3d34b05e58a4f1cb98f02d11015b99b.1428"
        }
      end

      it "creates a new user object with a mandate" do
        Timecop.freeze(Time.zone.at(jwt_auth_time + 10.seconds))

        expect {
          json_post_v2 "/api/app/oauth/apple", auth: auth
        }.to change(User, :count).and change(Mandate, :count)

        expect(response.status).to eq(201)

        Timecop.return
      end

      it "returns 401 if the auth token is no longer valid" do
        Timecop.freeze(Time.zone.at(jwt_auth_time + 30.minutes))

        json_post_v2 "/api/app/oauth/apple", auth: auth

        expect(response.status).to eq(401)
        expect(json_response.errors.auth.token).to be_present

        Timecop.return
      end
    end
  end
end
