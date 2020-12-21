# frozen_string_literal: true

require "rails_helper"

RSpec.describe SignatureService do
  let(:mandate) { create(:mandate) }
  context ".download_contractdata_and_save_to_mandate" do
    let(:session_id)                   { "fake_session_id" }
    let(:mandate_document_no_bio_data) { "mandate document no biometric data" }
    let(:mandate_document_biometric)   { "mandate document with biometric data" }
    let(:png_signature)                { "png signature" }
    let(:documents)                    { double :documents }
    let(:signatures)                   { double :signatures, get: png_signature }

    before do
      allow(Insign).to receive(:documents).and_return(documents)
      allow(Insign).to receive(:signatures).and_return(signatures)

      allow(documents).to \
        receive(:get).with(
          session_id: "fake_session_id",
          document_id: "docid1",
          include_biodata: true
        ).and_return(mandate_document_biometric)

      allow(documents).to \
        receive(:get).with(
          session_id: "fake_session_id",
          document_id: "docid1",
          include_biodata: false
        ).and_return(mandate_document_no_bio_data)
    end

    it "builds the mandate documents with the right documents from insign" do
      expect(mandate.documents).to receive(:create).with(asset: "data:application/pdf;base64," + mandate_document_biometric, document_type: DocumentType.mandate_document_biometric)
      expect(mandate.documents).to receive(:create).with(asset: "data:application/pdf;base64," + mandate_document_no_bio_data, document_type: DocumentType.mandate_document)
      expect(mandate).to receive(:create_signature).with(asset: "data:image/png;base64,"+png_signature)
      described_class.download_contractdata_and_save_to_mandate(mandate,session_id)
    end

    context "constants" do
      it { expect(described_class).to have_constant(:SESSION_CONFIG) }
      it { expect(described_class).to have_constant(:COORDINATES) }
    end

    describe ".coordinates" do
      let(:keys) { %i[page x0 y0 w h] }
      let(:coordinates) { described_class::COORDINATES }

      it "has coordinates keys and values" do
        keys.each do |key|
          expect(coordinates.fetch(key)).to be > 0
        end
      end
    end
  end
end
