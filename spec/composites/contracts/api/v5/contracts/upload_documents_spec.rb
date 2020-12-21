# frozen_string_literal: true

require "rails_helper"

describe "POST /api/contracts/:id/upload_documents", :integration, type: :request do
  let(:customer) { create :customer, :self_service }
  let(:contract) { create(:contract, :details_missing, customer_id: customer.id) }
  let(:product) { Product.find(contract.id) }
  let(:other_customer) { create(:customer) }
  let(:other_customer_contract) { create(:product, analysis_state: :details_missing, mandate_id: other_customer.id) }

  let(:file) do
    fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
  end

  it do
    # not logged in
    post_v5 "/api/contracts/#{contract.id}/upload_documents", files: [file, file]
    expect(response.status).to eq 401

    login_customer(customer, scope: :user)

    # trying to upload document for non-existing contract
    post_v5 "/api/contracts/12345/upload_documents", files: [file]
    expect(response.status).to eq 404
    expect(json_response).to eq("errors" => [{"title" => ClarkAPI::API::ErrorCode::NOT_FOUND}])

    # trying to upload documents to other user's contract
    post_v5 "/api/contracts/#{other_customer_contract.id}/upload_documents", files: [file, file]
    expect(response.status).to eq 404
    expect(json_response).to eq("errors" => [{"title" => ClarkAPI::API::ErrorCode::NOT_FOUND}])

    # trying to upload invalid document results in bad request
    post_v5 "/api/contracts/12345/upload_documents", files: "string"
    expect(response.status).to eq 400
    expect(json_response[:errors].first.title).to include("message body does not match declared format")

    # upload proper documents to the contract
    post_v5 "/api/contracts/#{contract.id}/upload_documents", files: [file, file]
    documents_data = json_response["data"]
    document = documents_data.first

    expect(response.status).to eq 201
    expect(Document.where(documentable: product).size).to eq(2)
    expect(product.analysis_state).to eq("under_analysis")

    expect(documents_data.count).to eq(2)
    expect(document["type"]).to eq("document")
    expect(document["id"]).to be_a(Integer)
    expect(document["attributes"]["url"]).to be_a(String)
    expect(document["attributes"]["created_at"]).to be_a(String)
    expect(document["attributes"]["content_type"]).to be_a(String)
    expect(document["attributes"]["file_name"]).to eq("blank.pdf")
  end
end
