# frozen_string_literal: true

require "rails_helper"

describe "Instant Advices API", :integration, type: :request do
  describe "GET /api/contracts/:id/instant-advice" do
    before do
      allow(Features).to receive(:active?).and_call_original
      allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(true)
    end

    context "when not logged in" do
      it "returns a 401 error" do
        json_get_v5 "/api/contracts/1/instant-advice"
        expect(response.status).to eq 401
      end
    end

    context "when logged in" do
      let(:customer) { create(:customer, :self_service) }
      let(:user) { customer }
      let(:contract) { create(:product, analysis_state: :details_complete, mandate_id: customer.id) }

      before { login_customer(user, scope: :user) }

      context "when feature switch is off" do
        before do
          allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(false)
        end

        it "returns a 401 error" do
          json_get_v5 "/api/contracts/1/instant-advice"
          expect(response.status).to eq 404
        end
      end

      context "and the customer does not own the contract" do
        let(:user) { create(:customer, :self_service) }

        it "returns a 404 error" do
          json_get_v5 "/api/contracts/#{contract.id}/instant-advice"
          expect(response.status).to eq 404
        end
      end

      context "and there is no product with given id" do
        it "returns a 404 error" do
          contract_id = 123
          json_get_v5 "/api/contracts/#{contract_id}/instant-advice"
          expect(response.status).to eq 404
        end
      end

      context "but there is no instant advice" do
        let(:company_ident) { "nope" }
        let(:category_ident) { "nope" }

        it "returns 404" do
          json_get_v5 "/api/contracts/#{contract.id}/instant-advice"
          expect(response.status).to be 404
        end
      end

      context "request instant-advice for Clark 1 product" do
        let(:clark_1_product) { create(:product, mandate_id: customer.id, analysis_state: nil) }
        let(:company_ident) { clark_1_product.company.ident }
        let(:category_ident) { clark_1_product.category.ident }
        let(:instant_assessment) do
          create(:instant_assessment, company_ident: company_ident, category_ident: category_ident)
        end

        it "returns instant-advice" do
          expected = {
            "category_ident" => instant_assessment.category_ident,
            "company_ident" => instant_assessment.company_ident,
            "category_description" => instant_assessment.category_description,
            "assessment_explanation" => instant_assessment.assessment_explanation,
            "total_evaluation" => {
              "description" => "",
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.average")
            },
            "popularity" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.popularity["description"]
            },
            "customer_review" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.very_good"),
              "description" => instant_assessment.customer_review["description"]
            },
            "coverage_degree" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.good"),
              "description" => instant_assessment.coverage_degree["description"]
            },
            "price_level" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.price_level["description"]
            },
            "claim_settlement" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.claim_settlement["description"]
            }
          }

          clark_1_product.update_attributes(analysis_state: nil)
          json_get_v5 "/api/contracts/#{clark_1_product.id}/instant-advice"

          expect(response.status).to eq 200
          expect(json_attributes).to eq(expected)
        end

        it "return 404 if the customer isn't permitted" do
          response_obj =  double :response_obj
          allow(Customer).to receive(:instant_advice_permitted?).and_return(response_obj)
          allow(response_obj).to receive(:failure?).and_return(true)
          json_get_v5 "/api/contracts/#{contract.id}/instant-advice"
          expect(response.status).to eq 404
        end
      end

      context "and there is a instant advice for contract" do
        let(:company_ident) { contract.company.ident }
        let(:category_ident) { contract.category.ident }
        let(:instant_assessment) do
          create(:instant_assessment, company_ident: company_ident, category_ident: category_ident)
        end

        it "returns instant advice" do
          expected = {
            "category_ident" => instant_assessment.category_ident,
            "company_ident" => instant_assessment.company_ident,
            "category_description" => instant_assessment.category_description,
            "assessment_explanation" => instant_assessment.assessment_explanation,
            "total_evaluation" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.average"),
              "description" => ""
            },
            "popularity" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.popularity["description"]
            },
            "customer_review" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.very_good"),
              "description" => instant_assessment.customer_review["description"]
            },
            "coverage_degree" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.good"),
              "description" => instant_assessment.coverage_degree["description"]
            },
            "price_level" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.price_level["description"]
            },
            "claim_settlement" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.claim_settlement["description"]
            }
          }

          json_get_v5 "/api/contracts/#{contract.id}/instant-advice"
          expect(response.status).to eq 200

          expect(json_attributes).to eq(expected)
        end

        it "return 404 if the customer isn't permitted" do
          response_obj =  double :response_obj
          allow(Customer).to receive(:instant_advice_permitted?).and_return(response_obj)
          allow(response_obj).to receive(:failure?).and_return(true)
          json_get_v5 "/api/contracts/#{contract.id}/instant-advice"
          expect(response.status).to eq 404
        end
      end
    end
  end

  describe "GET /api/contracts/:category_ident/:company_ident/instant-advice" do
    before do
      allow(Features).to receive(:active?).and_call_original
      allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(true)
    end

    let(:customer) { create(:customer, :self_service) }
    let(:user) { customer }
    let(:instant_assessment) do
      create(:instant_assessment, company_ident: create(:company).ident, category_ident: create(:category).ident)
    end
    let(:request_url) do
      "/api/contracts/#{instant_assessment.category_ident}/#{instant_assessment.company_ident}/instant-advice"
    end

    context "when not logged in" do
      it "returns a 401 error" do
        json_get_v5 request_url
        expect(response.status).to eq 401
      end
    end

    context "when logged in" do
      before { login_customer(user, scope: :user) }

      context "when feature switch is off" do
        before do
          allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(false)
        end

        it "returns a 404 error" do
          json_get_v5 request_url
          expect(response.status).to eq 404
        end
      end

      context "request instant-advice with category_ident and company_ident combination" do
        it "returns instant-advice" do
          expected = {
            "category_ident" => instant_assessment.category_ident,
            "company_ident" => instant_assessment.company_ident,
            "category_description" => instant_assessment.category_description,
            "assessment_explanation" => instant_assessment.assessment_explanation,
            "total_evaluation" => {
              "description" => "",
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.average")
            },
            "popularity" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.popularity["description"]
            },
            "customer_review" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.very_good"),
              "description" => instant_assessment.customer_review["description"]
            },
            "coverage_degree" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.good"),
              "description" => instant_assessment.coverage_degree["description"]
            },
            "price_level" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.price_level["description"]
            },
            "claim_settlement" => {
              "value" => I18n.t("composites.contracts.constituents.instant_advice.mapping.bad"),
              "description" => instant_assessment.claim_settlement["description"]
            }
          }

          json_get_v5 request_url

          expect(response.status).to eq 200
          expect(json_attributes).to eq(expected)
        end

        it "return 404 if the customer isn't permitted" do
          response_obj =  double :response_obj
          allow(Customer).to receive(:instant_advice_permitted?).and_return(response_obj)
          allow(response_obj).to receive(:failure?).and_return(true)
          json_get_v5 request_url
          expect(response.status).to eq 404
        end
      end
    end
  end
end
