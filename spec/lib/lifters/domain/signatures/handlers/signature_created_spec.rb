# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Signatures::Handlers::SignatureCreated do
  subject(:handler) { described_class.new }

  let(:opportunity) { create :shallow_opportunity }

  let!(:document) do
    create :document, documentable: opportunity, metadata: {insign: {session_id: "S_ID"}}
  end

  it "updates insign stats" do
    handler.process(
      sessionid: "S_ID",
      data: {signatureStatusSession: {numSignatures: 2, numSignaturesDone: 1}}
    )
    expect(document.reload.insign["num_signatures"]).to eq 2
    expect(document.reload.insign["num_signatures_done"]).to eq 1
  end
end
