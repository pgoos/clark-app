# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Retirement::Process::Products::SubmitDocuments, :integration do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate }

  describe "PATCH /products/submit_documents/:product_id" do
    let(:product) { create(:product, :retirement_overall_personal_product, mandate: user.mandate) }
    let(:params) do
      {ids: [documents.map(&:id)]}
    end

    before { login_as user, scope: :user }

    context "when documents from the current mandate" do
      let(:documents) do
        create_list(:document, 2, :retirement_document, documentable: user.mandate)
      end

      it "responds with success 200" do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_documents/#{product.id}", params

        expect(response).to be_successful
      end
    end

    context "when documents not associated with mandate" do
      let(:documents) do
        create_list(:document, 2, :retirement_document, documentable: create(:mandate))
      end

      it "responds with 422" do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_documents/#{product.id}", params

        expect(response.status).to eq(422)
      end
    end

    context "when product doesnt belong to the mandate" do
      let(:product) { create(:product, :retirement_overall_personal_product) }
      let(:documents) do
        create_list(:document, 2, :retirement_document, documentable: user.mandate)
      end

      it "responds with not found" do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_documents/#{product.id}", params

        expect(response).to be_not_found
      end
    end

    context "when params in the wrong format" do
      let(:invalid_params) do
        {id: [0]}
      end

      it "responds with 422" do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_documents/#{product.id}", invalid_params

        expect(response).to be_bad_request
      end
    end
  end

  describe "POST /products/submit_documents" do
    let(:params) do
      {ids: [documents.map(&:id)]}
    end

    before { login_as user, scope: :user }

    context "when documents from the current mandate" do
      let(:documents) do
        create_list(:document, 2, :retirement_document, documentable: user.mandate)
      end

      it "responds with success 201" do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_documents", params

        expect(response).to be_created
      end
    end

    context "when documents not associated with mandate" do
      let(:documents) do
        create_list(:document, 2, :retirement_document, documentable: create(:mandate))
      end

      it "responds with 422" do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_documents", params

        expect(response.status).to eq(422)
      end
    end

    context "when params in the wrong format" do
      let(:invalid_params) do
        {id: [0]}
      end

      it "responds with 422" do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_documents", invalid_params

        expect(response).to be_bad_request
      end
    end
  end
end
