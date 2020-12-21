# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manager::BaseController, :integration, type: :controller do
  # Inherited Resources hack to allow anonymous controller
  # https://github.com/activeadmin/inherited_resources/issues/364
  described_class.class_exec do
    def self.name
      "BaseController"
    end
  end

  controller do
    def index
      render json: current_user.id
    end
  end

  described_class.class_exec do
    def self.name
      super
    end
  end

  context "with authentication" do
    it "redirects to 401 without cookie or session" do
      get :index, params: {locale: "de"}
      expect(response).to redirect_to("/login")
    end

    it "returns 200 when authenticated" do
      user = create(:user, mandate: create(:mandate))
      sign_in user, scope: :user
      get :index, params: {locale: "de"}
      expect(response).to have_http_status :ok
      expect(response.body.to_i).to eq user.id
    end

    it "returns 200 when there is a cookie and admin login" do
      mandate = create(:mandate, user: create(:user))
      admin = create(:admin)
      sign_in(admin, scope: :admin)
      request.cookies["signed-as"] = mandate.id
      get :index, params: {locale: "de"}
      expect(response).to have_http_status :ok
      expect(response.body.to_i).to eq mandate.user.id
    end

    it "does not allow request without adming being logged in" do
      mandate = create(:mandate, user: create(:user))
      request.cookies["signed-as"] = mandate.id
      get :index, params: {locale: "de"}
      expect(response).to redirect_to("/login")
    end
  end
end
