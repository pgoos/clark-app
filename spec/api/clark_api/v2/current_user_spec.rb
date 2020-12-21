# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::CurrentUser, :clark_with_master_data do
  context "GET /api/current_user" do
    context "user" do
      it "returns the current logged in user" do
        user = create(:user, mandate: create(:mandate, customer_state: "mandate_customer"))
        login_as(user, scope: :user)

        json_get_v2 "/api/current_user"

        expect(response.status).to eq(200)
        expect(json_response.user.email).to eq(user.email)
        expect(json_response.user.mandate.customer_state).to eq(user.mandate.customer_state)
      end

      it "returns the number of unread important messages" do
        user = create(:user, mandate: create(:mandate))
        login_as(user, scope: :user)

        json_get_v2 "/api/current_user"

        expect(response.status).to eq(200)
        expect(json_response.user.unread_important_messages).to eq(0)
      end

      it "returns customer_state nil for clark1 customer" do
        clark1_user = create(:user, mandate: create(:mandate))
        login_as(clark1_user, scope: :user)

        json_get_v2 "/api/current_user"

        mandate = json_response.user.mandate

        expect(mandate).to include(:customer_state)
        expect(mandate.customer_state).to be_nil
      end

      it "returns last retirement check date" do
        user = create(:user, :with_mandate)
        finished_at = Time.current
        create(:questionnaire_response, :retirementcheck, :completed, mandate: user.mandate, finished_at: finished_at)
        login_as(user, scope: :user)

        json_get_v2 "/api/current_user"

        expect(json_response.user).to include(:last_retirementcheck_done_at)
        expect(json_response.user.last_retirementcheck_done_at).to eq(finished_at.utc.iso8601)
      end

      it "returns last demand check date" do
        user = create(:user, :with_mandate)
        finished_at = Time.current
        create(
          :questionnaire_response, :completed,
          mandate: user.mandate, finished_at: finished_at,
          questionnaire: create(:bedarfscheck_questionnaire)
        )
        login_as(user, scope: :user)

        json_get_v2 "/api/current_user"

        expect(json_response.user).to include(:last_demandcheck_done_at)
        expect(json_response.user.last_demandcheck_done_at).to eq(finished_at.utc.iso8601)
      end

      context "home24 user with free insurance" do
        it "returns the home24_free_product flag as true" do
          user = create(
            :user,
            mandate: create(
              :mandate,
              :home24_with_data,
              :with_free_home24_product
            )
          )

          login_as(user, scope: :user)

          json_get_v2 "/api/current_user"

          expect(json_response.user.home24_free_product).to be(true)
        end
      end

      context "non home24_user" do
        it "returns the home24_free_product flag as false" do
          user = create(:user, mandate: create(:mandate))

          login_as(user, scope: :user)

          json_get_v2 "/api/current_user"

          expect(json_response.user.home24_free_product).to be(false)
        end
      end
    end

    context "lead" do
      it "returns the current lead" do
        lead = create(:lead, mandate: create(:mandate, customer_state: "prospect"))
        login_as(lead, scope: :lead)

        json_get_v2 "/api/current_user"

        expect(response.status).to eq(200)
        expect(json_response.lead.email).to eq(lead.email)
        expect(json_response.lead.mandate.customer_state).to eq(lead.mandate.customer_state)
      end

      it "returns the number of unread important messages" do
        lead = create(:lead, mandate: create(:mandate))
        login_as(lead, scope: :lead)

        json_get_v2 "/api/current_user"

        expect(response.status).to eq(200)
        expect(json_response.lead.unread_important_messages).to eq(0)
      end
    end

    it "returns 401 if the user is not singed in" do
      json_get_v2 "/api/current_user"
      expect(response.status).to eq(401)
    end
  end

  context "PUT /api/current_user" do
    it "updates the currents users email-address" do
      user = create(:user, mandate: create(:mandate))
      login_as(user, scope: :user)

      email = "brand_new@email.com"

      json_put_v2 "/api/current_user", email: email

      expect(response.status).to eq(200)
      expect(json_response.user.email).to eq(email)
      expect(User.find(user.id).email).to eq(email)
    end

    it "updates the currents leads email-address" do
      lead = create(:lead, mandate: create(:mandate))
      login_as(lead, scope: :lead)

      email = "brand_new@email.com"

      json_put_v2 "/api/current_user", email: email

      expect(response.status).to eq(200)
      expect(json_response.lead.email).to eq(email)
      expect(lead.reload.email).to eq(email)
      expect(lead).to be_active
    end

    it 'does update the currents leads email-address when email
    without plus is already in system' do
      user = create(:user, email: "test@email.com")
      lead = create(:lead, mandate: create(:mandate))
      login_as(lead, scope: :lead)

      email = "test+1@email.com"

      json_put_v2 "/api/current_user", email: email

      expect(response.status).to eq(200)
      expect(json_response.lead.email).to eq(email)
      expect(Lead.find(lead.id).email).to eq(email)
    end

    it 'allows users to register with plus emails when the base address
    is not already registered' do
      expect(User.find_by(email: "test@email.com")).to eq nil
      user = create(:user, email: "test+1@email.com")
      lead = create(:lead, mandate: create(:mandate))
      login_as(lead, scope: :lead)

      email = "test+2@email.com"

      json_put_v2 "/api/current_user", email: email

      expect(response.status).to eq(200)
      expect(json_response.lead.email).to eq(email)
      expect(Lead.find(lead.id).email).to eq(email)
    end

    it "prevents duplicate email signups" do
      user = create(:user, email: "test@email.com")
      lead = create(:lead, mandate: create(:mandate))
      login_as(lead, scope: :lead)

      email = "test@email.com"

      json_put_v2 "/api/current_user", email: email

      expect(response.status).not_to eq(200)
    end

    it "does not update any other fields on the user" do
      user = create(:user, mandate: create(:mandate))
      login_as(user, scope: :user)

      email = "brand_new@email.com"
      password = "12345"
      info = "quatsch"

      json_put_v2 "/api/current_user", email: email, password: password, info: info

      expect(response.status).to eq(200)
      expect(json_response.user.email).to eq(email)
      expect(User.find(user.id).email).to eq(email)
      expect(User.find(user.id).password).not_to eq(password)
      expect(User.find(user.id).info).not_to eq(info)
    end

    it "returns an error with when sending an invalid email" do
      user = create(:user, mandate: create(:mandate))
      login_as(user, scope: :user)

      email = "this_is_not_an_email"

      json_put_v2 "/api/current_user", email: email

      expect(response.status).to eq(400)
      expect(User.find(user.id).email).not_to eq(email)
    end

    it "returns 401 if the user is not singed in" do
      email = "brand_new@email.com"
      json_put_v2 "/api/current_user", email: email
      expect(response.status).to eq(401)
    end

    context "when lead has unfinished mandate funnel" do
      let(:current_lead) { create :lead, :with_mandate }
      let(:email)        { "brand_new@email.com" }

      let!(:old_lead) do
        create :lead, :anonymous_lead, email: email, mandate: old_mandate
      end

      before { login_as current_lead, scope: :lead }

      context "with in_creation status" do
        let(:old_mandate) { create :mandate, :in_creation }

        it "clears email and deactivate old mandate" do
          json_put_v2 "/api/current_user", email: email
          expect(response.status).to eq 200
          expect(json_response.lead.email).to eq email
          expect(Lead.find(current_lead.id).email).to eq email
          expect(old_lead.reload.email).to be_blank
          expect(old_lead).to be_inactive
        end
      end

      context "with created status" do
        let(:old_mandate) { create :mandate, :created }

        it "responds with an error" do
          json_put_v2 '/api/current_user', email: email
          expect(response.status).to eq 400
        end
      end

      context "with rejected status" do
        let(:old_mandate) { create :mandate, :rejected }

        it "responds with an error" do
          json_put_v2 '/api/current_user', email: email
          expect(response.status).to eq 400
        end
      end

      context "with revoked status" do
        let(:old_mandate) { create :mandate, :revoked }

        it "responds with an error" do
          json_put_v2 '/api/current_user', email: email
          expect(response.status).to eq 400
        end
      end
    end
  end
  # rubocop:disable Lint/AmbiguousBlockAssociation

  context "POST /api/current_user/resend_confirmation" do
    it "resends the confirmation email" do
      expect(MandateMailer).to receive_message_chain("confirmation_reminder.deliver_now")
      user = create(:user, mandate: create(:mandate), confirmed_at: nil, confirmation_sent_at: 12.days.ago, confirmation_token: "old-token")
      login_as(user, scope: :user)
      expect {
        json_post_v2 "/api/current_user/resend_confirmation"
        user.reload
      }.to change { user.confirmation_token }.and change { user.confirmation_sent_at }
      expect(response.status).to eq(200)
    end
    # rubocop:enable Lint/AmbiguousBlockAssociation

    it "not logged in to not resend the confirmation email" do
      user = create(:user, mandate: create(:mandate), confirmed_at: nil, confirmation_sent_at: 12.days.ago, confirmation_token: "old-token")

      expect do
        json_post_v2 "/api/current_user/resend_confirmation"
        user.reload
      end.not_to change { ActionMailer::Base.deliveries.count }

      expect(response.status).to eq(401)
    end

    it "no mandate to not resend the confirmation email" do
      user = create(:user, confirmed_at: nil, confirmation_sent_at: 12.days.ago, confirmation_token: "old-token")
      login_as(user, scope: :user)

      expect do
        json_post_v2 "/api/current_user/resend_confirmation"
        user.reload
      end.not_to change { ActionMailer::Base.deliveries.count }

      expect(response.status).to eq(412)
    end
  end

  # expect do
  #   json_post_v2 "/api/current_user/change_password"
  #   user.reload
  # end.to change { user.confirmation_token }.and change { user.confirmation_sent_at }.and change { ActionMailer::Base.deliveries.count }.by(1)

  describe "PATCH /api/current_user/preferred_locale" do
    subject { json_patch_v2 "/api/current_user/preferred_locale", params }

    context "when user with mandate is available" do
      let(:mandate) { create :mandate }
      let(:user) { create :user, mandate: mandate }

      before { login_as(user) }

      context "when an available locale is set" do
        let(:params) { {preferred_locale: :de} }

        it "changes the locale of the mandate" do
          expect { subject }.to change { mandate.reload.preferred_locale }.from(nil).to("de")
          expect(response.status).to be 200
        end
      end

      context "when locale is invalid" do
        let(:params) { {preferred_locale: :some_unsupported_locale} }

        it "does not change the locale of the mandate" do
          expect { subject }.not_to change { mandate.reload.preferred_locale }
          expect(response.status).to be 400
        end
      end
    end

    context "when no user with mandate is available" do
      let(:params) { {preferred_locale: :de} }

      it "returns a 401" do
        subject
        expect(response.status).to be 401
      end
    end
  end

  describe "POST /api/current_user/change_password" do
    let(:endpoint) { "/api/current_user/change_password" }
    let(:user)     { create(:user, mandate: create(:mandate)) }

    context "when password already changed" do
      it "returns an error" do
        user.mandate.update_attributes(info: user.mandate.info.merge(reset_password: true))

        login_as(user, scope: :user)
        json_post_v2 endpoint, user: {password: "Test1234", password_confirmation: "Test1234"}

        expect(response.status).to eq(400)
        expect(response.body).to include(I18n.t("grape.errors.messages.password_already_changed"))
      end
    end

    context "when no password is set" do
      it "returns an error" do
        user.mandate.update_attributes(info: user.mandate.info.merge(reset_password: false))

        login_as(user, scope: :user)
        json_post_v2 endpoint, user: {password: "", password_confirmation: ""}

        expect(response.status).to eq(400)
        expect(response.body).to include("Bitte gebe ein Passwort ein")
      end
    end

    context "when user has one-time password" do
      before do
        user.mandate.update_attributes(info: user.mandate.info.merge(reset_password: false))
        user.update_attributes(subscriber: false)

        login_as(user, scope: :user)

        @old_password_hash = user.encrypted_password
        @password = "#{('A'..'Z').to_a.sample}#{('a'..'z').to_a.sample}#{SecureRandom.hex(8)}"
      end

      it "changes the password" do
        json_post_v2 endpoint, user: {password: @password, password_confirmation: @password}
        expect(response.status).to eq(200)
        expect(user.reload.encrypted_password).not_to eq(@old_password_hash)
      end

      context "mark as subscriber context" do
        before do
          allow(Settings.clark_api.current_user.change_password).to receive(:subscriber).and_return(true)
        end

        it "changes the subscription state to true if false" do
          json_post_v2 endpoint, user: {password: @password, password_confirmation: @password}
          expect(user.reload.subscriber).to be_truthy
        end
      end

      it "does not change the subscription state in normal context" do
        json_post_v2 endpoint, user: {password: @password, password_confirmation: @password}
        expect(user.reload.subscriber).to be_falsey
      end
    end
  end

  describe "POST /api/current_user/change_initial_credentials" do
    let(:endpoint) { "/api/current_user/change_initial_credentials" }
    let(:user)     { create(:user, mandate: create(:mandate)) }

    context "when password already changed" do
      it "returns an error" do
        user.mandate.update_attributes(info: user.mandate.info.merge(reset_password: true))

        login_as(user, scope: :user)
        json_post_v2 endpoint, user: {email: "test@me.com", password: "Test1234", password_confirmation: "Test1234"}

        expect(response.status).to eq(400)
        expect(response.body).to include(I18n.t("grape.errors.messages.password_already_changed"))
      end
    end

    context "when email already changed" do
      it "returns an error" do
        user.mandate.update_attributes(info: user.mandate.info.merge(reset_email: true))

        login_as(user, scope: :user)
        json_post_v2 endpoint, user: {email: "test@me.com", password: "Test1234", password_confirmation: "Test1234"}

        expect(response.status).to eq(400)
        expect(response.body).to include(I18n.t("grape.errors.messages.email_already_changed"))
      end
    end

    context "missing or empty password param" do
      before do
        user.mandate.update_attributes(info: user.mandate.info.merge(reset_password: false))
        login_as(user, scope: :user)
      end

      it "returns an error when param is missing" do
        json_post_v2 endpoint, user: {email: "test@me.com"}

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["errors"]["user"]["password"]).to include("muss ausgefüllt werden")
      end

      it "returns an error when param is set to empty" do
        json_post_v2 endpoint, user: {email: "test@me.com", password: "", password_confirmation: ""}

        expect(response.status).to eq(400)
        parsed_body = JSON.parse(response.body)["errors"]["user"]
        expect(parsed_body["password"]).to include(I18n.t("grape.errors.messages.presence"))
        expect(parsed_body["password_confirmation"]).to include(I18n.t("grape.errors.messages.presence"))
      end
    end

    context "when password and email should be changed and params are valid" do
      before do
        user.mandate.update(reset_email: false, reset_password: false)
        login_as(user, scope: :user)
      end

      let!(:old_email) { user.email }
      let!(:old_password) { user.password }

      let(:new_email) { "not@afake.com" }
      let(:password) { "#{('A'..'Z').to_a.sample}#{('a'..'z').to_a.sample}#{SecureRandom.hex(8)}" }

      it "updates values and mandate reset flags" do
        json_post_v2 endpoint, user: {email: new_email, password: password, password_confirmation: password}

        user.reload

        expect(response.status).to eq(200)
        expect(user.email).not_to eq(old_email)
        expect(user.password).not_to eq(old_password)
        expect(user.subscriber).to be(true)
        expect(user.mandate.reset_email).to be(true)
        expect(user.mandate.reset_password).to be(true)
      end

      context "when updating user fails" do
        before do
          user.stub(:save).and_return(false)
        end

        it "should not update mandate reset flags" do
          json_post_v2 endpoint, user: {email: new_email, password: password, password_confirmation: password}

          user.reload

          expect(response.status).to eq(400)
          expect(user.mandate.reset_email).to be_falsy
          expect(user.mandate.reset_password).to be_falsy
        end
      end
    end
  end

  describe "POST /api/current_user/restore_authorization" do
    let!(:lead) do
      current_lead = create(:lead)
      Platform::LeadSessionRestoration.add_session_restoration_token(current_lead) # Decorates the lead with token
      current_lead
    end

    let(:endpoint) { "/api/current_user/restore_authorization" }
    let(:encrypted_token) { Platform::LeadSessionRestoration.send(:encrypt_restoration_token, lead.restore_session_token) }

    it "returns something" do
      json_post_v2 endpoint, restoration_token: encrypted_token

      expect(response.status).to eq(200)
      expect(json_response).to eq("success" => true)
    end
  end
end
