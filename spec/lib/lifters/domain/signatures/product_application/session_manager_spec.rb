# frozen_string_literal: true

require "rails_helper"
require "insign"

RSpec.describe Domain::Signatures::ProductApplication::SessionManager do
  let(:application) { described_class.new document }

  describe "#find_or_create" do
    let(:document)       { object_double Document.new, metadata: metadata }
    let(:session_states) { double :sessions, get: double(:session_state) }
    let(:metadata)       { {"insign" => {"session_id" => "SESSION_ID"}} }

    before do
      allow(Insign).to receive(:session_states).and_return(session_states)
    end

    context "when session is already created" do
      it "does not create a new one" do
        expect(application.find_or_create).to eq "SESSION_ID"
      end

      context "but it's expired" do
        let(:error) { Insign::Error.new "" }

        before do
          allow(session_states).to receive(:get).and_raise(error)
          allow(error).to receive(:session_expired?).and_return(true)
        end

        it "creates a new session" do
          expect(application).to receive(:create)
          application.find_or_create
        end
      end
    end

    context "when session does not exist" do
      let(:metadata) { {} }

      it "creates a new session" do
        expect(application).to receive(:create)
        application.find_or_create
      end
    end
  end

  describe "#create" do
    let(:opportunity) { object_double Opportunity.new, id: "OP_ID", mandate: mandate }
    let(:mandate)     { object_double Mandate.new, name: "U_NAME", phone: "+494213123213213" }
    let(:doc_type)    { object_double DocumentType.new, name: "DOC_TYPE" }
    let(:asset)       { double :asset, read: "ASSET" }
    let(:document)    { build :shallow_document, id: 99 }

    let(:insign_sessions)  { double :sessions, create: "SESSION_ID" }
    let(:insign_documents) { double :documents, create: "DOCUMENT" }

    before do
      allow(document).to receive_messages(
        documentable:  opportunity,
        document_type: doc_type,
        asset:         asset,
        save!:         true
      )

      allow(Insign).to receive_messages(
        sessions: insign_sessions,
        documents: insign_documents
      )

      allow_any_instance_of(Platform::UrlShortener).to receive(:url_with_host) \
        .with("/de/admin/opportunities/OP_ID").and_return("OPP_URL")
      allow_any_instance_of(Platform::UrlShortener).to receive(:url_with_host) \
        .with("/hooks/insign/events").and_return("WEBHOOK_URL")
    end

    it "creates an insign session" do
      session_params = {
        displayname:                 "DOC_TYPE",
        foruser:                     "U_NAME",
        appSupport:                  false,
        applosPerTouch:              true,
        applosKundePerSms:           true,
        applosKundePerSmsEmpfaenger: "04213123213213",
        embedBiometricData:          true,
        pdfEditorOnly:               true,
        aushaendigenPflicht:         false,
        callbackURL:                 "OPP_URL",
        serverSidecallbackURL:       "WEBHOOK_URL",
        documents:                   [{id: 99, displayname: "DOC_TYPE"}]
      }
      expect(insign_sessions).to receive(:create).with(session_params)
      application.create
    end

    it "creates a document within session" do
      expect(insign_documents).to \
        receive(:create).with(
          session_id:  "SESSION_ID",
          document_id: 99,
          document:    "ASSET"
        )
      application.create
    end

    it "stores session id in document" do
      expect(document).to receive(:save!)
      application.create
      expect(document.insign).to eq("session_id" => "SESSION_ID", "completed" => false)
    end
  end
end
