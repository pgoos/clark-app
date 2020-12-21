# frozen_string_literal: true

require "rails_helper"

describe ::Recommendations::Api::V5::Overview, :integration, type: :request do
  describe "GET /api/recommendations/.overview" do
    context "when user is not logged in" do
      it "returns 401 with error message" do
        json_get_v5 "/api/recommendations/.overview"

        expect(response.status).to eq 401
        error_message = JSON.parse(response.body)["errors"][0]["title"]
        expect(error_message).to eq("unauthenticated")
      end
    end

    context "when user is logged in" do
      let(:customer) { create(:customer, :prospect) }
      before do
        login_customer(customer, scope: :lead)
      end

      context "when user does not have recommendations" do
        it "returns 200" do
          json_get_v5 "/api/recommendations/.overview"

          expect(response.status).to eq 200
        end
      end

      context "when user has recommendations" do
        let(:questionnaire) { create(:questionnaire) }
        let(:category) do
          create(:category, :kapitallebensversicherung, questionnaire: questionnaire)
        end
        let(:category2) do
          create(
            :category, ident: "730c2a87", questionnaire: questionnaire, has_category_page: true, life_aspect: :things
          )
        end
        let(:offer) { create(:active_offer, mandate_id: customer.id) }
        let(:product) { create(:product) }
        let!(:opportunity) do
          create(:opportunity, mandate_id: customer.id, category: category, offer: offer, state: :offer_phase)
        end
        let!(:offer_option) { create(:offer_option, offer: offer, product: product) }
        let!(:recommendation) do
          create(:recommendation, category: category, mandate_id: customer.id)
        end
        let!(:recommendation2) do
          create(:recommendation, category: category2, mandate_id: customer.id)
        end
        let!(:dismissed_recommendation) do
          create(:recommendation, mandate_id: customer.id, dismissed: true)
        end

        it "returns 200 with active Recommendation data" do
          create(
            :product,
            category: category,
            mandate_id: customer.id,
            contract_ended_at: Time.current.yesterday
          )
          expected_recommendation_body = {
            "id" => recommendation.id,
            "type" => "recommendation",
            "state" => "offered",
            "category" => {
              "id" => category.id,
              "type" => "category",
              "ident" => category.ident,
              "name" => category.name,
              "description" => category.description,
              "life_aspect" => category.life_aspect,
              "questionnaire_ident" => category.questionnaire_identifier,
              "priority" => category.priority,
              "page_available" => false
            },
            "offer" => {
              "id" => offer.id,
              "type" => "offer",
              "cheapest_option" => {
                "payment" => {
                  "type" => "FormOfPayment",
                  "value" => product.premium_period.dasherize
                },
                "price" => {
                  "currency" => "EUR",
                  "value" => product.premium_price_cents
                }
              }
            }
          }

          category2_page = I18n.t("category_pages.#{category2.ident}")
          no_1_recommendation_body = {
            "id" => recommendation2.id,
            "type" => "number_one_recommendation",
            "state" => "recommended",
            "category" => {
              "id" => category2.id,
              "type" => "category_with_page",
              "ident" => category2.ident,
              "name" => category2.name,
              "description" => category2.description,
              "life_aspect" => category2.life_aspect,
              "questionnaire_ident" => category2.questionnaire_identifier,
              "priority" => category2.priority,
              "benefits" => category2_page[:benefits],
              "consultant_comment" => category2_page[:consultant_comment],
              "page_available" => true
            },
            "offer" => nil
          }
          json_get_v5 "/api/recommendations/.overview"

          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["data"]["attributes"]

          expect(response_body["recommendations"].count).to eq(2)
          expect(response_body["recommendations"].first).to eq(expected_recommendation_body)
          expect(response_body["recommendations"].pluck("id")).to include(recommendation2.id)
          expect(response_body["number_one_recommendation"]).to eq(no_1_recommendation_body)
        end

        context "when category page data is in database" do
          let(:category2) do
            create(:category, :category_page, :things, has_category_page: true)
          end

          it "retrieves the category page data properly" do
            create(
              :product,
              category: category,
              mandate_id: customer.id,
              contract_ended_at: Time.current.yesterday
            )

            no_1_recommendation_body = {
              "id" => recommendation2.id,
              "type" => "number_one_recommendation",
              "state" => "recommended",
              "category" => {
                "id" => category2.id,
                "type" => "category_with_page",
                "ident" => category2.ident,
                "name" => category2.name,
                "description" => category2.description,
                "life_aspect" => category2.life_aspect,
                "questionnaire_ident" => category2.questionnaire_identifier,
                "priority" => category2.priority,
                "benefits" => category2.benefits,
                "consultant_comment" => category2.consultant_comment,
                "page_available" => true
              },
              "offer" => nil
            }

            json_get_v5 "/api/recommendations/.overview"

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]["attributes"]["number_one_recommendation"]

            expect(response_body["category"]["benefits"]).not_to be_empty
            expect(response_body["category"]["consultant_comment"]).not_to be_empty
            expect(response_body).to eq(no_1_recommendation_body)
          end
        end
      end
    end
  end
end
