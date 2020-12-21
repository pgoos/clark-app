# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::WorkItems::ProductUpdatesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/work_items/product_updates")) }
  let(:admin) { create(:admin, role: role) }
  let(:product) { create(:product_gkv) }
  let(:document) { create(:document, documentable: product, document_type: DocumentType.customer_upload) }

  before { sign_in(admin) }

  describe "POST /:id/request_reupload" do
    before do
      allow(Documents::RequestReuploadJob).to receive(:perform_later).with(document.id, admin.id)
      post :request_reupload,
           params: {
             locale: I18n.locale,
             id: document.id,
             document: { document_type_id: DocumentType.request_document_reupload.id }
           }
    end

    it { expect(Documents::RequestReuploadJob).to have_received(:perform_later) }
    it { expect(response).to be_redirect }
    it { is_expected.to redirect_to("#{admin_root_path}#product_updates") }
    it { expect(document.reload.document_type).to eq DocumentType.request_document_reupload }

    context "with passing anchor parameter" do
      let(:anchor) { "customer_uploaded_contract_documents" }

      before do
        post :request_reupload,
             params: {
               locale: I18n.locale,
               id: document.id,
               document: { document_type_id: DocumentType.request_document_reupload.id },
               anchor: anchor
             }
      end

      it "should redirect to that anchor" do
        expect(subject).to redirect_to("#{admin_root_path}##{anchor}")
      end
    end
  end
end
