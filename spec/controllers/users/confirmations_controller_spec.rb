# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::ConfirmationsController, :integration, type: :controller do
  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  before {
    request.env["devise.mapping"] = Devise.mappings[:user]
  }

  let!(:tokens) { Devise.token_generator.generate(User, :confirmation_token) }

  let!(:user) do
    user = create(:user, mandate: create(:mandate))
    user.update_attributes(confirmed_at: nil, confirmation_token: tokens.last, confirmation_sent_at: Time.zone.now)
    user
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

  context "redirecting to ClarkApp" do
    before do
      user.devices << create(:device)
    end

    context "from desktop browser" do
      before do
        request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
      end

      it "does the normal redirect even if the user has a device" do
        get :show, params: {confirmation_token: tokens.first, locale: "de"}
        expect(response).not_to redirect_to(feed_path)
      end
    end
  end
end
