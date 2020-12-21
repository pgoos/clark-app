# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PaybackActivitiesController, :integration, type: :controller do
  let(:mandate) { create :mandate, :payback_with_data }
  let(:role) { create :role, permissions: Permission.where(controller: "admin/payback_activities") }
  let(:admin) { create :admin, role: role }
  let!(:business_event) do
    create(
      :business_event,
      entity_id: mandate.id,
      entity_type: mandate.class.name,
      metadata: {loyalty: {new: {payback: {paybackNumber: "1234"}}}}
    )
  end

  before { login_admin(admin) }

  describe "GET index" do
    context "when mandate has payback enabled" do
      it "responds with success and assigns correct data" do
        get :index, params: {mandate_id: mandate.id, locale: :de}

        expect(response).to have_http_status(:ok)
        expect(assigns(:mandate)).to eq mandate
        expect(assigns(:payback_number_add_date)).to eq business_event.created_at.strftime("%d/%m/%Y %H:%M")
      end
    end

    context "when mandate do not have payback enabled" do
      let(:mandate) { create :mandate }

      it "redirect to mandate show page" do
        get :index, params: {mandate_id: mandate.id, locale: :de}

        expect(response).to redirect_to([:admin, mandate])
        expect(controller).to set_flash[:alert].to("Kein Zugriff!")
      end
    end
  end
end
