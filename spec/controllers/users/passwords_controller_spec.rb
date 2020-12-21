# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::PasswordsController, :integration, type: :controller do
  let(:random_pw) { User.generate_random_pw }

  let!(:tokens) { Devise.token_generator.generate(User, :confirmation_token) }

  let!(:user) do
    user = create(:user, mandate: create(:mandate))
    user.update_attributes(confirmed_at: nil, confirmation_token: tokens.last, confirmation_sent_at: Time.zone.now)
    user
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "PUT #update" do
    context "from desktop browser" do
      it "redirects to main home page" do
        password_reset_token = user.send_reset_password_instructions
        new_password = random_pw
        response = put :update, params: {user: {reset_password_token:  password_reset_token,
                                                password:              new_password,
                                                password_confirmation: new_password}, locale: "de"}
        expect(response).to redirect_to("/de/app/manager")
      end

      it "answers with an error for empty password" do
        password_reset_token = user.send_reset_password_instructions
        new_password = ""
        response = put :update, params: {user: {reset_password_token:  password_reset_token,
                                                password:              new_password,
                                                password_confirmation: new_password}, locale: "de"}
        expect(response).to render_template(:edit)
        expect(response.status).to eq(200)
      end
    end
  end
end
