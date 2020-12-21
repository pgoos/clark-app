# frozen_string_literal: true

require "rails_helper"
require "insign"

RSpec.describe Domain::Signatures::Handlers::ProcessCompleted do
  subject(:handler) { described_class.new }

  let(:mandate)          { create :mandate }
  let(:opportunity)      { create :shallow_opportunity, mandate: mandate }
  let(:insign_documents) { double :documents, get: base64_pdf }
  let(:mailer)           { double :mailer, deliver_later: nil }
  let(:document_type)    { create :document_type, :product_application_for_signing }

  let!(:document) do
    create :document,
           documentable: opportunity,
           metadata: {insign: {session_id: "S_ID"}},
           document_type: document_type
  end

  let(:base64_pdf) do
    file = File.open(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
    Base64.encode64(file.read, &:read)
  end

  before do
    allow(Insign).to receive(:documents).and_return(insign_documents)
    allow(DocumentMailer).to receive(:product_application_fully_signed)
      .with(mandate, document).and_return(mailer)
  end

  it "updates document with a new asset" do
    expect(insign_documents).to \
      receive(:get).with(
        session_id: "S_ID",
        document_id: document.id,
        include_biodata: true
      )
    expect { handler.process(sessionid: "S_ID") }.to(change { document.reload.asset })
  end

  it "reset document insign session id" do
    handler.process(sessionid: "S_ID")
    expect(document.reload.insign["session_id"]).to be_blank
    expect(document.insign["completed"]).to eq true
  end

  it "delivers email" do
    expect(mailer).to receive(:deliver_later)
    handler.process(sessionid: "S_ID")
  end

  context "with other than product_application_for_signing document type" do
    let(:document_type) { create :document_type, :additional_product_application_for_signing }

    it "does not deliver email" do
      expect(mailer).not_to receive(:deliver_later)
      handler.process(sessionid: "S_ID")
    end
  end
end
