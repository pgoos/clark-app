# frozen_string_literal: true

require "rails_helper"
describe OmniauthCallbacksController, :integration, type: :controller do
  describe ".facebook" do
    let(:auth) do
      Hashie::Mash.new("provider" => "facebook",
                       "uid"      => "734576096665654",
                       "info"     => {
                         "name"       => "Bruce Wayne",
                         "first_name" => "Bruce",
                         "last_name"  => "Wayne",
                         "email"      => nil
                       })
    end

    before do
      request.env["devise.mapping"] = Devise.mappings[:user]
      request.env["omniauth.auth"] = auth
    end

    context "when user is already signed in" do
      let(:user) { create :user }

      before do
        sign_in user

        request.env["HTTP_REFERER"] = root_path

        get :facebook
      end

      it "redirects an user back" do
        expect(response).to redirect_to root_path
      end
    end

    context "without an account" do
      let(:email) { "email@test.clark.de" }

      before do
        request.env["omniauth.auth"].info.email = email
      end

      it "redirects to login page with error message" do
        get :facebook
        expect(response).to redirect_to(new_user_session_url)
        expect(flash[:alert]).to eq(I18n.t("omniauth.facebook.not_existing", email: email))
      end

      it "doesn't create new user" do
        expect { get :facebook }.not_to change(User, :count)
      end
    end

    context "when there is existing linked account" do
      let(:user) {
        create :user,
               identities: [
                 create(:identity,
                        provider: request.env["omniauth.auth"].provider,
                        uid: request.env["omniauth.auth"].uid)
               ]
      }

      before do
        request.env["omniauth.auth"].info.email = user.email

        get :facebook
      end

      it "redirects to after sign_in path" do
        expect(response).to redirect_to subject.after_sign_in_path_for(user)
      end
    end
  end
end
