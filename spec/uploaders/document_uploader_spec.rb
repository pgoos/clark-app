# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentUploader, :integration do
  context "with mandate document" do
    it "does not change the document name if the name of mandate changes" do
      asset = Rack::Test::UploadedFile.new(
        Rails.root.join("spec", "support", "assets", "mandate.pdf")
      )
      mandate = create(:mandate)
      document = create(
        :document,
        document_type: DocumentType.mandate_document,
        documentable: mandate, asset: asset
      )
      document_name = document.asset.to_s
      mandate.update!(first_name: "New Name")
      document.update!(qualitypool_id: 123)

      expect(document.reload.asset.to_s).to eq document_name

      mandate_prefix = Mandate.model_name.human.downcase
      expect(document.reload.asset.to_s).to match mandate_prefix
    end
  end

  it "sets an extension of the origin file" do
    asset = Rack::Test::UploadedFile.new(
      Rails.root.join("spec", "support", "assets", "ruby_logo.png")
    )

    product = create(:product)

    document = create(
      :document,
      document_type: DocumentType.offer_documents,
      documentable: product,
      asset: asset
    )

    expect(document.asset.filename).to eq "offer_documents.png"
  end
end
