# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manager::InsurancesController, :integration, type: :controller do
  describe "GET #index" do
    context "not signed in" do
      it "redirects to the login screen" do
        get :index, params: {locale: "de"}
        expect(response).to redirect_to(new_user_session_path(locale: ""))
      end
    end

    context "as a device lead" do
      let(:mandate) { create(:mandate) }
      let(:device_lead) { create(:device_lead, mandate: mandate) }

      before do
        sign_in device_lead, scope: :lead
      end

      it "redirects to the register screen when having completed mandate" do
        mandate.info[:wizard_steps] = %i[targeting profiling confirming]
        mandate.save

        get :index, params: {locale: "de"}

        expect(response).to render_template("redirect-to-lead-register")
      end
    end
  end
end
