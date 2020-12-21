# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DocumentsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/documents")) }
  let(:admin) { create(:admin, role: role) }

  before { sign_in(admin) }

  describe "GET edit_in_insign" do
    let(:opportunity)   { create :shallow_opportunity }
    let(:document_type) { create :document_type, :product_application_for_signing }

    let(:document) do
      create :document, documentable: opportunity, document_type: document_type
    end

    before do
      allow_any_instance_of(Domain::Signatures::ProductApplication::SessionManager)
        .to receive(:find_or_create).and_return("SESSION_ID")
    end

    context "When setting insign.edit_in_insign.relative_url" do
      before do
        allow(Settings).to(
          receive_message_chain("insign.edit_in_insign.relative_url")
            .and_return(relative_url_enabled)
        )

        allow(Settings).to receive_message_chain("insign.base_url").and_return(base_url)
      end

      let(:base_url) { "http://localhost:8080/insign" }

      let(:call) do
        get(
          :edit_in_insign,
          params: { locale: :de, opportunity_id: opportunity.id, id: document.id }
        )
      end

      describe "is false" do
        let(:relative_url_enabled) { false }

        it "redirects user to insign pdf editor with base url" do
          call

          redirect_url = "#{base_url}/index?sessionid=SESSION_ID"
          expect(response).to redirect_to redirect_url
        end
      end

      describe "is true" do
        let(:relative_url_enabled) { true }

        it "redirects user to insign pdf editor with relative url" do
          call

          redirect_url = "/insign/index?sessionid=SESSION_ID"
          expect(response).to redirect_to redirect_url
        end
      end
    end

    context "when document is not compatible with insign editor" do
      let(:document_type) { DocumentType.advisory_documentation }

      it "redirects user back" do
        get :edit_in_insign,
            params: {locale: :de, opportunity_id: opportunity.id, id: document.id}
        expect(response).to redirect_to admin_root_url
      end
    end
  end

  describe "POST general_insurance_conditions_emails" do
    let(:mandate)       { create :mandate }
    let(:opportunity)   { create :shallow_opportunity, mandate: mandate }
    let(:document_type) { DocumentType.general_insurance_conditions }
    let(:mailer)        { double :mailer, deliver_now: nil }

    let(:document) do
      create :document,
             documentable: opportunity,
             document_type: document_type
    end

    before do
      allow(DocumentMailer) .to receive(:general_insurance_conditions_notification)
        .with(mandate, document).and_return(mailer)
    end

    it "sends an email with general insurance conditions to customer" do
      expect(mailer).to receive(:deliver_now)
      post :general_insurance_conditions_emails,
           params: {locale: :de, opportunity_id: opportunity.id, id: document.id}
    end

    context "with wrong document type" do
      let(:document_type) { DocumentType.advisory_documentation }

      it "does not send an email" do
        expect(mailer).not_to receive(:deliver_now)
        post :general_insurance_conditions_emails,
             params: {locale: :de, opportunity_id: opportunity.id, id: document.id}
        expect(response).to redirect_to admin_root_url
      end
    end
  end

  describe "PATCH destroy" do
    let(:mandate) { create(:mandate) }
    let(:document_id) { create(:document, documentable: mandate).id }

    it "should delete the document, if it could be found and return no content" do
      delete :destroy_ajax, params: {locale: :de, mandate_id: mandate.id, id: document_id, format: :json}
      expect(response).to have_http_status(:no_content)
      expect(Document.where(id: document_id)).to be_blank
    end
  end

  describe "GET asset" do
    let(:mandate)       { create :mandate }
    let(:opportunity)   { create :shallow_opportunity, mandate: mandate }
    let(:document_type) { DocumentType.general_insurance_conditions }
    let(:document) { create :document, documentable: opportunity, document_type: document_type }

    context "when requested as attachment" do
      it "returns the file" do
        get :asset, params: {locale: :de, mandate_id: mandate.id, id: document.id, disposition: :attachment}
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
        expect(response.header["Content-Disposition"]).to \
          eq "attachment; filename=\"allgemeine_versicherungsbedingungen.pdf\""
      end
    end

    context "when requested as inline" do
      it "returns the file" do
        get :asset, params: {locale: :de, mandate_id: mandate.id, id: document.id, disposition: :inline}
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
        expect(response.header["Content-Disposition"]).to \
          eq "inline; filename=\"allgemeine_versicherungsbedingungen.pdf\""
      end
    end
  end

  describe "POST /merge" do
    let(:inquiry_category) { create(:inquiry_category) }
    let(:documents) { create_list(:document, 2, :customer_upload, documentable: inquiry_category) }
    let(:common_params) do
      {
        locale: I18n.locale,
        documentable_id: inquiry_category.id,
        documentable_type: "inquiry_categories"
      }
    end

    it "merge documents into one" do
      document_ids = documents.map(&:id)
      params = common_params.merge(document_ids: document_ids)
      post :merge_documents, params: params

      document = inquiry_category.documents.last
      number_pages = CombinePDF.new(document.asset.path).pages.size

      expect(number_pages).to be(2)
    end

    it "saves merged document" do
      document_ids = documents.map(&:id)
      params = common_params.merge(document_ids: document_ids)

      expect {
        post :merge_documents, params: params
      }.to change(inquiry_category.documents, :count).from(2).to(1)
    end

    describe "invalid requests" do
      context "when only one document is sent" do
        let(:document) { create(:document, :customer_upload, documentable: inquiry_category) }

        it "returns an error" do
          params = common_params.merge(document_ids: [document.id])
          post :merge_documents, params: params

          expect(response).to have_http_status(:bad_request)
        end
      end

      context "when one of documents is encrypted" do
        let(:document) { create(:document, :customer_upload, documentable: inquiry_category) }
        let(:encrypted_file_path) { Rails.root.join("spec", "fixtures", "files", "encrypted_document.pdf") }
        let(:encrypted_file) { Rack::Test::UploadedFile.new(encrypted_file_path) }
        let(:encrypted_document) {
          create(:document,
                 documentable: inquiry_category,
                 asset: encrypted_file,
                 document_type: DocumentType.customer_upload)
        }

        it "returns an error" do
          params = common_params.merge(document_ids: [document.id, encrypted_document.id])
          post :merge_documents, params: params

          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe "create" do
    context "with multiple documents attached" do
      let(:product) { create(:product) }
      let(:document) do
        Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "assets", "mandate.pdf"))
      end

      let(:documents_attrs) do
        {
          "0" => {
            "asset" => [
              document,
              document
            ],
            "document_type_id" => DocumentType.deckungsnote.id
          },
          "1" => {
            "asset" => [
              document
            ],
            "document_type_id" => DocumentType.greeting.id
          }
        }
      end

      it "creates documents" do
        expect {
          post :create, params: {locale: I18n.locale, product_id: product.id, documents: documents_attrs}
        }.to change(Document, :count).by(3)

        expect(product.reload.documents.count).to eq 3
      end
    end
  end
end
