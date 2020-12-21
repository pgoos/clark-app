# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account::UsersController, :integration, type: :controller do
  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

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

  describe "PUT update" do
    let(:user)     { create :user, email: "foo@bar.com" }
    let(:new_pass) { Settings.seeds.default_password.reverse }

    let(:params) do
      {locale: I18n.locale, user: user_params}
    end

    let(:user_params) do
      {email: "bar@foo.com", password: new_pass, password_confirmation: new_pass}
    end

    before { sign_in user }

    it "updates user email and password" do
      expect { put :update, params: params }.to(change { user.reload.encrypted_password })
      expect(user.email).to eq "bar@foo.com"
      expect(response).to redirect_to edit_account_user_path
    end

    context "with invalid data" do
      let(:user_params) { {email: "INVALID_EMAIL"} }

      it "shows an error" do
        put :update, params: params
        expect(flash[:alert]).to eq I18n.t("account.users.update.failure")
      end
    end
  end
end
