# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account::WizardsController, :integration, type: :controller do
  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  # Many methods would send out the greeting mail at the current config,
  # let's catch those cases until we move this out to an observer
  before do
    allow(MandateMailer).to receive_message_chain("greeting.deliver_now")
  end

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Filter
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Actions
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
  describe "Info package action" do
    context "as a user" do
      before do
        @user = create(:user, mandate: create(:mandate))
        sign_in @user
      end

      it "shows the info package page" do
        get :info_package, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end

      it "adds info package to newsletters" do
        expect {
          patch :info_package, params: {locale: I18n.locale, mandate: {newsletter: "1"}}
        }.to change { Mandate.find(@user.mandate_id).newsletter.count }.by(1)

        expect(response).to have_http_status(:success)
      end

      it "does not add with missing confirmation" do
        expect {
          patch :info_package, params: {locale: I18n.locale, mandate: {newsletter: ""}}
        }.not_to change { Mandate.find(@user.mandate_id).newsletter.count }

        expect(response).to have_http_status(:not_acceptable)
      end

      it "does not add to newsletter multiple times" do
        mandate = @user.mandate
        mandate.newsletter = [:info_package]
        mandate.save

        expect {
          patch :info_package, params: {locale: I18n.locale, mandate: {newsletter: "1"}}
        }.not_to change { Mandate.find(@user.mandate_id).newsletter.count }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "targeting action" do
    context "as a user" do
      it "opens the targeting page" do
        @user = create(:user, mandate: create(:mandate))
        sign_in @user

        get :targeting, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as a lead" do
      it "opens the targeting page" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        sign_in device_lead, scope: :lead

        get :targeting, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as not logged in" do
      it "does not open the targeting page" do
        get :targeting, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "profiling action" do
    context "as a user" do
      it "opens the profiling page" do
        @user = create(:user, mandate: create(:mandate))
        sign_in @user

        get :profiling, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as a lead" do
      it "opens the profiling page" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        sign_in device_lead, scope: :lead

        get :profiling, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as not logged in" do
      it "does not open the profiling page" do
        get :profiling, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "confirming action (GET)" do
    context "as a user" do
      it "opens the confirming page" do
        @user = create(:user, mandate: create(:mandate))
        sign_in @user

        get :confirming, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as a lead" do
      it "opens the confirming page" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        sign_in device_lead, scope: :lead

        get :confirming, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as not logged in" do
      it "does not open the confirming page" do
        get :confirming, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "confirming action (PATCH)" do
    before do
      allow_any_instance_of(Mandate).to receive(:signature_png_base64).and_return("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACn\nej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVO\nRK5CYII=\n")
    end

    context "as a user" do
      it "opens the confirming page" do
        user = create(:user, mandate: create(:signed_unconfirmed_mandate))
        sign_in user

        patch :confirming, params: {locale: I18n.locale, mandate: {confirmed: "1", tos_accepted: "1"}}

        expect(response).to redirect_to("/de/account/wizard/finished")
      end
    end

    context "as a lead in the clark app" do
      it "opens the confirming page" do
        allow_any_instance_of(Account::WizardsController).to receive(:mobile_client?).and_return(true)

        device_lead = create(:device_lead, mandate: create(:signed_unconfirmed_mandate))
        sign_in device_lead, scope: :lead

        patch :confirming, params: {locale: I18n.locale, mandate: {confirmed: "1", tos_accepted: "1"}}

        expect(response).to redirect_to("/de/signup?next_user_path=%2Fde%2Faccount%2Fwizard%2Ffinished")
      end
    end

    context "as not logged in" do
      it "does not open the confirming page" do
        patch :confirming, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "finished action" do
    context "as a user" do
      it "opens the finished page" do
        @user = create(:user, mandate: create(:mandate))
        sign_in @user

        get :finished, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as a lead" do
      it "opens the finished page" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        sign_in device_lead, scope: :lead

        get :finished, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as not logged in" do
      it "does not open the finished page" do
        get :finished, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "info_package action" do
    context "as a user" do
      it "opens the info_package page" do
        @user = create(:user, mandate: create(:mandate))
        sign_in @user

        get :info_package, params: {locale: I18n.locale}

        expect(response).to have_http_status(:success)
      end
    end

    context "as a lead" do
      it "opens the info_package page" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        sign_in device_lead, scope: :lead

        get :info_package, params: {locale: I18n.locale}

        expect(response).not_to have_http_status(:success)
      end
    end

    context "as not logged in" do
      it "does not open the info_package page" do
        get :info_package, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end
end
