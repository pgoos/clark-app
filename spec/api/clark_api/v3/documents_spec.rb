# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Documents, :integration do
  let(:user) { create(:user, mandate: create(:mandate)) }
  let(:user_without_product) { create(:user, mandate: create(:mandate)) }

  before(:all) do
    @file = fixture_file_upload("#{Rails.root}/spec/fixtures/files/blank.pdf")
  end

  context "POST /api/documents/:documentable_type/:documentable_id" do
    context "with a product" do
      let!(:product) { create(:product, mandate: user.mandate) }

      it "should attach a file to a product" do
        login_as(user, scope: :user)
        post_v3 "/api/documents/product/#{product.id}", file: [@file]
        expect(product.documents.size).to eq(1)
        created_document = json_response.dig("product", "created_document")
        expect(created_document).to be_present
      end

      it "should attach multiple files to a product" do
        login_as(user, scope: :user)
        post_v3 "/api/documents/product/#{product.id}", file: [@file, @file]
        expect(product.documents.size).to eq(2)
        res = JSON.parse(response.body)
        expect(res.dig("product", "documents").class).to eq(Array)
        created_document = json_response.dig("product", "created_document")
        expect(created_document).to be_present
      end

      it "should reject an upload by non authenticated user" do
        post_v3 "/api/documents/product/#{product.id}", file: [@file]
        expect(product.documents.size).to eq(0)
      end

      it "should reject an upload with wrong id" do
        login_as(user, scope: :user)
        post_v3 "/api/documents/product/123459991291", file: [@file]
        expect(product.documents.size).to eq(0)
      end

      it "should reject an upload to a documentable that doesn't belong to the user" do
        login_as(user_without_product, scope: :user)
        post_v3 "/api/documents/product/#{product.id}", file: [@file]
        expect(product.documents.size).to eq(0)
      end
    end

    context "with a mandate" do
      let(:file2) { fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf")) }

      before do
        login_as(user, scope: :user)

        post_v3 "/api/documents/mandate/#{user.mandate.id}", file: [@file, file2]
      end

      it "attachs the document to the mandate" do
        expect(user.mandate.documents.size).to eq(2)
      end

      it "returns created_document key" do
        resp = JSON.parse(response.body)
        last_created_document = user.mandate.documents.last

        expect(resp.dig("mandate", "created_document", "id")).to eq(last_created_document.id)
        created_document = json_response.dig("mandate", "created_document")
        expect(created_document).to be_present
      end
    end
  end
end
