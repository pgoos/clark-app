# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V4::Mandates::TermsAcceptance, :integration do
  let(:lead) { create(:lead, mandate: create(:mandate)) }
  let(:user) { create(:user, mandate: create(:mandate)) }

  context "PATCH /api/mandates/:id/termsacceptance" do
    it "sets the mandates tos_accepted_at to current time" do
      login_as(user, scope: :user)

      json_patch_v4 "/api/mandates/#{user.mandate.id}/termsacceptance"

      expect(response.status).to eq(200)
      expect(user.mandate.tos_accepted).to be_truthy
    end

    it "sets the mandates tos_accepted_at to current time as a lead" do
      lead = create(:lead, mandate: create(:signed_unconfirmed_mandate))
      login_as(lead, scope: :lead)

      json_patch_v4 "/api/mandates/#{lead.mandate.id}/termsacceptance"

      expect(response.status).to eq(200)
      expect(lead.mandate.tos_accepted).to be_truthy
    end

    it "errors when the mandate id does not match" do
      create(:signature, signable: user.mandate)
      login_as(user, scope: :user)

      json_patch_v4 "/api/mandates/0/termsacceptance"

      expect(response.status).to eq(404)
    end

    it "returns 401 if the user is not singed in" do
      user = create(:user, mandate: create(:signed_unconfirmed_mandate))
      json_patch_v4 "/api/mandates/#{user.mandate.id}/termsacceptance"
      expect(response.status).to eq(401)
    end
  end

  context "POST /api/mandates/:id/datasecuritytermsupload" do
    let(:file) do
      fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
    end

    def post_v4(endpoint, payload_hash={})
      post endpoint, params: payload_hash, headers: {
        "CONTENT_TYPE" => "application/json",
        "ACCEPT" => ClarkAPI::V4::Root::API_VERSION_HEADER
      }
    end

    it "should attach a file to a mandate" do
      login_as(lead, scope: :lead)

      post_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload", file: [file]

      lead.reload
      expect(lead.mandate.documents.size).to eq(1)
    end

    it "should attach multiple files to an inquiry category" do
      login_as(lead, scope: :lead)

      post_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload", file: [file, file]

      lead.reload
      expect(lead.mandate.documents.size).to eq(2)
    end

    it "should reject an upload by non authenticated user" do
      post_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload", file: [file]

      lead.reload
      expect(lead.mandate.documents.size).to eq(0)
    end

    it "should reject an upload by a mandate with id different than the current session mandate" do
      login_as(lead, scope: :lead)

      post_v4 "/api/mandates/#{user.mandate.id}/datasecuritytermsupload", file: [file]

      lead.reload
      expect(lead.mandate.documents.size).to eq(0)
    end

    it "should have the uploaded documents in the response" do
      login_as(lead, scope: :lead)

      post_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload", file: [file, file]

      lead.reload
      expect(lead.mandate.documents.size).to eq(2)

      mandate = JSON.parse(response.body)["mandate"]
      expect(mandate["documents"].count).to eq(2)
    end

    context "when a document for biometric is already present, it deletes the existing one" do
      let(:document) do
        create(:document,
               document_type: DocumentType.mandate_document_biometric, created_at: 2.days.ago)
      end

      it "deletes the previous document" do
        login_as(lead, scope: :lead)
        lead.mandate.documents << document
        post_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload", file: [file]

        lead.reload
        expect(lead.mandate.documents.size).to eq(1)
      end
    end
  end

  context "DELETE  /api/mandates/:id/datasecuritytermsupload/:document_id" do
    context "when the user has a file existing" do
      context "when the file is of type mandate_document_biometric" do
        let(:document) {
          create(:document, document_type: DocumentType.mandate_document_biometric,
                            created_at: 2.days.ago)
        }
        let(:document_two) do
          create(:document,
                 document_type: DocumentType.confirmation_reminder,
                 created_at: 2.days.ago)
        end

        before do
          lead.mandate.documents << document
          user.mandate.documents << document_two
        end

        it "deletes the documents" do
          login_as(lead, scope: :lead)
          expect(lead.mandate.documents.size).to eq(1)

          json_delete_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload/#{document.id}"
          lead.reload
          expect(lead.mandate.documents.size).to eq(0)

          mandate = JSON.parse(response.body)["mandate"]
          expect(mandate["documents"].count).to eq(0)
        end

        it "does not let a mandate delete a document not owned by them" do
          login_as(lead, scope: :lead)
          expect(user.mandate.documents.size).to eq(1)
          json_delete_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload/#{document_two.id}"

          lead.reload
          expect(user.mandate.documents.size).to eq(1)

          expect(response.status).to eq(404)
        end
      end

      context "when the file is not of type mandate_document_biometric" do
        let(:document) { create(:document, document_type: DocumentType.contract_information, created_at: 2.days.ago) }
        let(:document_two) do
          create(:document,
                 document_type: DocumentType.mandate_document_biometric,
                 created_at: 2.days.ago)
        end

        before do
          lead.mandate.documents << document
          lead.mandate.documents << document_two
        end

        it "does not deletes the documents" do
          login_as(lead, scope: :lead)
          expect(lead.mandate.documents.size).to eq(2)
          json_delete_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload/#{document.id}"
          lead.reload
          expect(lead.mandate.documents.size).to eq(2)

          json_delete_v4 "/api/mandates/#{lead.mandate.id}/datasecuritytermsupload/#{document_two.id}"

          lead.reload
          expect(lead.mandate.documents.size).to eq(1)
        end
      end
    end
  end
end
