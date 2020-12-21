# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::UpgradeJourney::Interactors::DownloadSignature do
  subject(:download) { described_class.new }

  let(:insign_documents)  { double :documents }
  let(:insign_signatures) { double :signatures }

  before do
    allow(Insign).to receive(:documents).and_return insign_documents
    allow(Insign).to receive(:signatures).and_return insign_signatures

    allow(insign_documents).to receive(:get).with(
      session_id: "INSIGN_SESSION_ID",
      document_id: SignatureService::DOCUMENT_ID,
      include_biodata: true
    ).and_return("PDF_WITH_BIODATA")

    allow(insign_documents).to receive(:get).with(
      session_id: "INSIGN_SESSION_ID",
      document_id: SignatureService::DOCUMENT_ID,
      include_biodata: false
    ).and_return("PDF_WITH_BIODATA")

    allow(insign_signatures).to receive(:get).with(
      session_id: "INSIGN_SESSION_ID",
      document_id: SignatureService::DOCUMENT_ID,
      signature_id: SignatureService::SIGNATURE_ID
    ).and_return("PNG_SIGNATURE")
  end

  it "exposes files downloaded from Insign" do
    result = download.("INSIGN_SESSION_ID")
    expect(result).to be_successful
    expect(result.pdf_with_biodata).to eq "PDF_WITH_BIODATA"
    expect(result.pdf_without_biodata).to eq "PDF_WITH_BIODATA"
    expect(result.png_signature).to eq "PNG_SIGNATURE"
  end
end
