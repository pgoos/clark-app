# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::InquiryCategories, :integration do
  let(:endpoint) { "/api/inquiry_categories" }
  let(:access_token) { @access_token }
  let(:mandate) { create(:mandate, owner_ident: @client.partnership_ident) }
  let(:company) { create(:company) }
  let(:category) { create(:category) }
  let(:valid_headers) { {"Authorization" => access_token} }
  let(:invalid_headers) { {"Authorization" => nil} }
  let(:pdf_file) do
    fixture_file_upload(Rails.root.join("spec", "fixtures", "dummy-mandate.pdf"), "application/pdf")
  end

  before do
    generate_auth_access_token

    create(:inquiry, mandate: mandate, company: company, categories: [category])
  end

  describe "Create inquiry category" do
    let(:valid_params) do
      {
        inquiry_category: {mandate_id:     mandate.id,
                           company_ident:  company.ident,
                           category_ident: category.ident}
      }
    end

    context "wrong auth access token" do
      it "returns an authorized error" do
        partners_post endpoint, payload_hash: valid_params, headers: invalid_headers

        expect(response.status).to eq(401)
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end

    context "request param is missing" do
      it "returns the error object" do
        partners_post endpoint, headers: valid_headers

        expect(response.status).to eq(400)
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end

    context "all params are valid and the inquiry doesn't exist" do
      # A different mandate with no inquiries defined
      let(:other_mandate) { create(:mandate, owner_ident: @client.partnership_ident) }
      let(:other_params) { valid_params.deep_merge(inquiry_category: {mandate_id: other_mandate.id}) }

      it "returns the inquiry_category object" do
        partners_post endpoint, payload_hash: other_params, headers: valid_headers

        expect(response.status).to eq(201)
        expect(response.body).to match_response_schema("partners/20170213/inquiry_category")
      end
    end

    context "the inquiry_category do exists (idempotency)" do
      it "returns the same inquiry_category object" do
        expect {
          3.times { partners_post endpoint, payload_hash: valid_params, headers: valid_headers }
        }.not_to change(mandate.inquiries, :count)

        expect(response.status).to eq(200)
        expect(response.body).to match_response_schema("partners/20170213/inquiry_category")
      end
    end

    context "request different inquiry categories" do
      let(:other_category) { create(:category) }
      let(:invalid_params) do
        valid_params.deep_merge(inquiry_category: {category_ident: other_category.ident})
      end

      it "should not create more inquiries" do
        expect {
          partners_post endpoint, payload_hash: invalid_params, headers: valid_headers
        }.not_to change(mandate.inquiries, :count)

        expect(response.status).to eq(200)
        expect(response.body).to match_response_schema("partners/20170213/inquiry_category")
      end
    end

    context "the inquiry_category do exists with in progress state" do
      context "pending" do
        before do
          mandate.inquiries.each(&:accept!)
        end

        it "returns the inquiry object  and `conflict` http status" do
          partners_post endpoint, payload_hash: valid_params, headers: valid_headers

          expect(response.status).to eq(409)
          expect(response.body)
            .to match_response_schema("partners/20170213/error_conflict_inquiry")
        end
      end

      context "contacted" do
        before do
          mandate.inquiries.each(&:accept!)
          mandate.inquiries.each(&:contact!)
        end

        it "returns the inquiry object and `conflict` http status" do
          partners_post endpoint, payload_hash: valid_params, headers: valid_headers

          expect(response.status).to eq(409)
          expect(response.body)
            .to match_response_schema("partners/20170213/error_conflict_inquiry")
        end
      end
    end
  end

  describe "Mark inquiry category as deleted" do
    let(:inquiry_category) { mandate.inquiries.last.inquiry_categories.first }
    let(:delete_endpoint) { "#{endpoint}/#{inquiry_category.id}" }

    context "wrong auth access token" do
      it "returns an authorized error" do
        partners_delete delete_endpoint, headers: invalid_headers

        expect(response.status).to eq(401)
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end

    context "authorized" do
      it "returns the inquiry_category object" do
        partners_delete delete_endpoint, headers: valid_headers

        expect(response.status).to eq(200)
        expect(response.body).to match_response_schema("partners/20170213/inquiry_category")
      end
    end
  end

  describe "Upload inquiry category document" do
    let(:payload)                { {document: {asset: pdf_file}} }
    let(:inquiry_category)       { create(:inquiry_category, inquiry: mandate.inquiries.last) }
    let(:upload_endpoint)        { "#{endpoint}/#{inquiry_category.id}/documents" }

    context "wrong auth access token" do
      it "returns an unauthorized error" do
        partners_post upload_endpoint, payload_hash: payload, headers: invalid_headers, json: false

        expect(response.status).to eq(401)
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end

    context "when inquiry category is in progress" do
      it "returns document payload if inquiry category has `in_progress` state" do
        partners_post upload_endpoint, payload_hash: payload, headers: valid_headers, json: false

        expect(response.status).to eq(201)
        expect(response.body).to match_response_schema("partners/20170213/document")
      end
    end

    context "when inquiry category is finished" do
      before do
        inquiry_category.complete!
      end

      it "returns method_not_allowed" do
        partners_post upload_endpoint, payload_hash: payload, headers: valid_headers, json: false

        expect(response.status).to eq(405)
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end
  end
end
