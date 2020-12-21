# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Opportunities::SourceDescriptionsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/opportunities/source_descriptions")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "POST /" do
    it do
      expect {
        post :create, params: { locale: I18n.locale, opportunity_source_description: { description: "NewDescription" } }
      }.to change(Opportunity::SourceDescription, :count).by(1)

      expect(subject).to redirect_to(admin_opportunity_source_descriptions_path(locale: "de"))
    end
  end

  describe "PATCH /id" do
    let(:source_description) { create(:opportunity_source_description) }
    let(:new_description) { "new description" }

    it do
      params = { id: source_description.id, opportunity_source_description: { description: new_description } }
      put :update, params: params.merge(locale: I18n.locale)
      expect(source_description.reload.description).to eq new_description
      expect(subject).to redirect_to(admin_opportunity_source_descriptions_path(locale: "de"))
    end
  end

  describe "DELETE /id" do
    let(:source_description) { create(:opportunity_source_description) }
    let(:new_description) { "new description" }

    it do
      params = { id: source_description.id }
      expect {
        delete :destroy, params: params.merge(locale: I18n.locale)
      }.to change(Opportunity::SourceDescription, :count).by(-1)

      expect(subject).to redirect_to(admin_opportunity_source_descriptions_path(locale: "de"))
    end
  end
end
