# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Documents, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "POST /api/admin/documents/:document_id/copy" do
    context "with documentable_type, documentable_id and document_id" do
      let(:params) { {documentable_type: "Product", documentable_id: 100} }
      let(:paramsInvalid) { {documentable_type: "Invalid", documentable_id: 100} }
      let(:document) { create :document }

      it "creates a copy of document provided by id" do
        json_admin_post_v1("/api/admin/documents/#{document.id}/copy", params)
        expect(response.status).to eq 200
      end

      it "throws error with invalid documentable type" do
        json_admin_post_v1("/api/admin/documents/#{document.id}/copy", paramsInvalid)
        expect(response.status).to eq 500
      end
    end
  end
end
