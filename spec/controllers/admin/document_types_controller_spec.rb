# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DocumentTypesController, :integration, type: :controller do
  let(:document_type) { create(:document_type, key: "DT1") }
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/document_types")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET new" do
    it "responds with success" do
      get :new, params: { locale: I18n.locale }

      assert_response :success
    end
  end

  describe "GET show" do
    it "responds with success" do
      get :show, params: { id: document_type.id, locale: I18n.locale }

      assert_response :success
    end

    it "responds with success for document_type with empty description" do
      document_type.update_columns(description: nil)

      get :show, params: { id: document_type.id, locale: I18n.locale }

      assert_response :success
      expect(response).to render_template(:show)
    end
  end
end
