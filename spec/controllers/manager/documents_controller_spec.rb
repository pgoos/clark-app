# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manager::DocumentsController, :integration do
  describe "GET #asset" do
    before do
      @user = create(:user, mandate: create(:mandate))
      sign_in @user, scope: :user
    end

    context "when documentable_type is a product" do
      let(:repository_double) { instance_double(Domain::Documents::CustomerDocumentsRepository) }

      it "returns the correct document" do
        expect(Domain::Documents::CustomerDocumentsRepository).to receive(:new).and_return(repository_double)
        expect(repository_double).to \
          receive(:find_by_id_at_product).with(id: 2, product_id: 1)

        get "asset", params: {locale: :de, documentable_type: "products", documentable_id: 1, document_id: 2}
      end
    end

    context "when documentable_type is a mandate" do
      it "returns the correct document" do
        mandate = @user.mandate
        document = create(:document, documentable: mandate, document_type: DocumentType.damage)
        get "asset", params: {
          locale: :de,
          documentable_type: "mandate",
          documentable_id: mandate.id,
          document_id: document.id
        }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
        expect(response.header["Content-Disposition"]).to eq "inline; filename=\"schaden.pdf\""
      end
    end

    context "when documentable_type is a parent_plan" do
      let(:repository_double) { instance_double(Domain::Documents::ParentPlansPermissionRepository) }

      it "returns the correct document" do
        expect(Domain::Documents::ParentPlansPermissionRepository).to receive(:new).and_return(repository_double)
        expect(repository_double).to \
          receive(:find).with(document_id: 2, parent_plan_id: 1)

        get "asset", params: {locale: :de, documentable_type: "parent_plans", documentable_id: 1, document_id: 2}
      end
    end
  end
end
