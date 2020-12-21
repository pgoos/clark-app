# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Salesforce::Opportunities::DocumentsController, type: :controller do
  let(:role) do
    create(
      :role,
      permissions: Permission.where(controller: "admin/salesforce/opportunities/documents", action: %w[index new])
    )
  end
  let(:mandate) { create :mandate }
  let(:admin) { create(:admin, :sales_consultant, role: role) }
  let(:document1) { create :document, document_type: DocumentType.general_insurance_conditions }
  let(:document2) { create :document, document_type: DocumentType.produktinformationsblatt }
  let(:opportunity) { create(:opportunity, mandate: mandate, documents: [document1, document2]) }

  before do
    sign_in(admin)
  end

  describe "#index" do
    before { get :index, params: { locale: I18n.locale, opportunity_id: opportunity.id } }

    it "returns documents and 200" do
      expect(response.status).to eq(200)
      expect(assigns(:documents)).to match_array([document1, document2])
    end
  end

  describe "#new" do
    before { get :new, params: { locale: I18n.locale, opportunity_id: opportunity.id } }

    it "returns 200" do
      expect(response.status).to eq(200)
    end
  end
end
