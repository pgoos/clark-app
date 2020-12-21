# frozen_string_literal: true

require "rails_helper"

RSpec.describe StartersController, :integration, type: :controller do
  #
  # Actions
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  describe "POST #create" do
    context "when a user is not logged in" do
      it "returns a starter response" do
        post :create, params: {name:   "Tester",
                               email:  "tester@test.de",
                               phone:  "0123456789",
                               format: :js}
        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq "text/javascript; charset=utf-8"
        expect(response).to render_template(:create)
      end

      it "sends out emails" do
        expect {
          post :create, params: {name:   "Tester",
                                 email:  "tester@test.de",
                                 phone:  "0123456789",
                                 format: :js}
        }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end
  end
end
