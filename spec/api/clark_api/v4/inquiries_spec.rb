# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Inquiries, :integration do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate }

  describe "GET /api/inquiries/:inquiry_id/documents" do
    let(:inquiry) { create :inquiry, :pending, mandate: mandate }

    it "responds with a list of documents" do
      document1 = create :document, :customer_upload, documentable: inquiry
      create :document, :advisory_documentation, documentable: inquiry

      login_as(user, scope: :user)
      json_get_v4 "/api/inquiries/#{inquiry.id}/documents"

      expect(response.status).to eq 200
      expect(json_response.documents.size).to eq 1
      expect(json_response.documents[0]["id"]).to eq document1.id
    end

    context "when customer is not authenticated" do
      it "responds with an error" do
        json_get_v4 "/api/inquiries/#{inquiry.id}/documents"

        expect(response.status).to eq 401
      end
    end
  end

  describe "POST /api/inquiries/:inquiry_id/documents" do
    let(:inquiry) { create :inquiry, :pending, mandate: mandate }

    let(:files) do
      [
        fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf")),
        fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
      ]
    end

    it "creates the new documents out of sent files" do
      login_as(user, scope: :user)
      post_v4 "/api/inquiries/#{inquiry.id}/documents", files: files

      expect(response.status).to eq 201
      expect(inquiry.documents.size).to eq 2
      expect(json_response.documents.map { |d| d["id"] }).to match_array inquiry.documents.map(&:id)
    end

    context "when customer is not authenticated" do
      it "responds with an error" do
        post_v4 "/api/inquiries/#{inquiry.id}/documents", params: {files: files}

        expect(response.status).to eq 401
      end
    end
  end
end
