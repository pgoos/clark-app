# frozen_string_literal: true

require "swagger_helper"

describe ::Offers::Api::Admin::V2::Documents, type: :request, integration: true, swagger_doc: "v2/admin.yaml" do
  let("Content-Type".to_sym) { "application/x-www-form-urlencoded" }
  let(:accept) { "application/vnd.clark-admin-v2+json" }
  let(:admin) { create(:admin) }
  let(:offer) { opportunity.offer }
  let(:document_type) { create(:document_type, key: "test1234") }
  let(:opportunity) { create(:opportunity_with_offer) }
  let(:vvg_information_package) { DocumentType.vvg_information_package }
  let(:vglneu) { DocumentType.offer_new }
  let(:file_extensions) { %w[.jpg .jpeg .png .pdf] }
  let(:file_format_error_message) do
    I18n.t("dry_validation.errors.rules.file_extension", formats: file_extensions.join(", "))
  end

  let(:file) do
    fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
  end

  let(:product) { offer.offer_options.first.product }

  path "/api/admin/offers/manual_creation/documents" do
    post "Create document" do
      consumes "multipart/form-data"
      parameter name: :product_id, in: :query, type: :string
      parameter name: :document_type_key, in: :query, type: :string
      parameter name: :file, in: :formData, type: :file, required: true
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authorization" do
        let(:product) { offer.offer_options.first.product }
        let!(:product_id) { product.id }
        let!(:document_type_key) { document_type.key }

        run_test!
      end

      response "201", "for valid params" do
        let(:product) { offer.offer_options.first.product }
        let!(:product_id) { product.id }
        let!(:document_type_key) { document_type.key }
        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test! do |_response|
          document = product.documents.last
          expect(json_response).to eq(
            {
              "data" => {
                "id"         => document.id,
                "type"       => "document",
                "attributes" => {
                  "id"               => document.id,
                  "document_type_key" => document_type_key,
                  "url"              => document.url,
                  "content_type"     => document.content_type,
                  "file_name"        => document.file_name,
                  "name"             => document.name,
                  "created_at"       => document.created_at.iso8601.to_s
                }
              }
            }
          )
        end
      end

      response "422", "for invalid params" do
        let!(:product_id) { product.id }
        let!(:document_type_key) { 999_999_999_999 }
        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test!
      end

      response "422", "File with wrong extension" do
        let(:file) do
          fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "file_sample.txt"))
        end

        let(:product) { offer.offer_options.first.product }
        let!(:product_id) { product.id }
        let!(:document_type_key) { document_type.key }
        let!(:vvg_information_package) { DocumentType.vvg_information_package }

        let!(:vvg_information_package_document) do
          create :document, document_type: vvg_information_package, documentable: product
        end

        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test! do |_response|
          expect(json_response[:error]).to eq([file_format_error_message])
        end
      end

      response "422", "File with size more then 15 mb" do
        let(:file) do
          fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
        end

        let(:product) { offer.offer_options.first.product }
        let!(:product_id) { product.id }
        let!(:document_type_key) { document_type.key }
        let!(:vvg_information_package) { DocumentType.vvg_information_package }

        let!(:vvg_information_package_document) do
          create :document, document_type: vvg_information_package, documentable: product
        end

        let!(:authentication) { login_as(admin, scope: :admin) }

        before do
          allow_any_instance_of(Tempfile)
            .to receive(:size).and_return(16_000_000)
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.file_size")
          expect(json_response[:error]).to eq([translation])
        end
      end

      response "201", "for the document UPDATE" do
        let(:product) { offer.offer_options.first.product }
        let!(:product_id) { product.id }
        let!(:vvg_information_package) { DocumentType.vvg_information_package }

        let!(:vvg_information_package_document) do
          create :document, document_type: vvg_information_package, documentable: product
        end

        let!(:contract_information_document) do
          create :document, document_type: DocumentType.contract_information, documentable: product
        end

        let!(:document_type_key) { contract_information_document.document_type.key }

        let(:file_name) { "blank.pdf" }
        let(:file) do
          fixture_file_upload(Rails.root.join("spec", "fixtures", "files", file_name))
        end

        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test! do |_response|
          expect(json_response["data"]["attributes"]["url"]).to include(file_name)
        end
      end
    end
  end

  path "/api/admin/offers/manual_creation/documents/{id}" do
    delete "Delete document" do
      consumes "application/json"
      parameter name: :id, in: :path, schema: { type: :string }, description: "Document ID"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authorization" do
        let!(:document) { create :document, document_type: document_type, documentable: product }
        let!(:id) { document.id }

        run_test!
      end

      response "204", "deletes document for valid id" do
        let!(:document) { create :document, document_type: document_type, documentable: product }
        let!(:id) { document.id }

        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test!
      end

      response "422", "for invalid id" do
        let!(:id) { 999_999_999_999 }
        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test! do |_response|
          expect(json_response).to eq({ "error" => ["Couldn't find Document with an out of range value for 'id'"] })
        end
      end

      response "400", "validated vvg document deletion" do
        let!(:vvg_information_package_document) do
          create :document, document_type: vvg_information_package, documentable: product
        end

        let!(:id) { vvg_information_package_document.id }

        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test! do |_response|
          error_message_transtation = I18n.t("grape.errors.messages.documents.VVG_information_package")
          expect(json_response["errors"]).to eq({ "api" => { "id" => [error_message_transtation] } })
        end
      end

      response "400", "validated vergleichsdokument document deletion" do
        let!(:vglneu_document) do
          create :document, document_type: vglneu, documentable: product
        end

        let!(:id) { vglneu_document.id }

        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test! do |_response|
          error_message_transtation = I18n.t("grape.errors.messages.documents.VGLNEU")
          expect(json_response["errors"]).to eq({ "api" => { "id" => [error_message_transtation] } })
        end
      end
    end
  end
end
