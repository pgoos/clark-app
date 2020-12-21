# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Documents, :integration do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate, :created }

  describe "GET /api/documents/:documentable_type/:documentable_id" do
    let(:documentable) { create :product, mandate: mandate }

    it "responds with documents" do
      document1 = create :document, :advisory_documentation, documentable: documentable
      document2 = create :document, :customer_upload, documentable: documentable

      login_as user, scope: :user
      json_get_v2 "/api/documents/products/#{documentable.id}"

      expect(response.status).to eq 200
      expect(json_response["document"]&.count).to eq 1
      expect(json_response["document"][0]["id"]).to eq document2.id
    end

    context "mandate customer state is nil" do
      let!(:mandate) { create(:mandate, :accepted, customer_state: nil) }
      let!(:document_type) { create(:document_type, :visible_to_mandate_customer) }
      let!(:document) do
        create(:document, :advisory_documentation, documentable: documentable, document_type: document_type)
      end

      it "returns documents" do
        login_as user, scope: :user
        json_get_v2 "/api/documents/products/#{documentable.id}"

        expect(response.status).to eq 200
        expect(json_response["document"]&.count).to eq 1
        expect(json_response["document"][0]["id"]).to eq document.id
      end
    end

    context "when documentable type is not supported" do
      let(:documentable) { mandate }

      it "responds with an error" do
        login_as user, scope: :user
        json_get_v2 "/api/documents/mandates/#{documentable.id}"

        expect(response.status).to eq 403
      end
    end

    context "when current mandate does not have an access to documentable " do
      let(:documentable) { create :product }

      it "responds with an error" do
        login_as user, scope: :user
        json_get_v2 "/api/documents/products/#{documentable.id}"

        expect(response.status).to eq 401
      end
    end

    context "when not authorized" do
      it "responds with an error" do
        json_get_v2 "/api/documents/products/#{documentable.id}"

        expect(response.status).to eq 401
      end
    end
  end
end
