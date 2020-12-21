# encoding : utf-8
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Products, :integration do
  include SettingsHelpers

  let(:user) { create(:user, mandate: create(:mandate)) }

  describe "GET /api/products/:id" do
    let(:product) { create(:product, mandate: user.mandate) }

    it "gets the product associated with the mandate" do
      login_as(user, scope: :user)

      json_get_v2 "/api/products/#{product.id}"

      expect(response.status).to eq(200)
    end

    it "returns false for finished with questionnaire when not done" do
      login_as(user, scope: :user)

      json_get_v2 "/api/products/#{product.id}"

      expect(json_response.customer_finished_questionnaire).to be_falsy
    end

    context "acquisition details" do
      context "commision payouts count is zero" do
        before do
          product.acquisition_commission_price = 10
          product.acquisition_commission_payouts_count = 0
          product.save!
        end

        it "should have commision details acquisition" do
          login_as(user, scope: :user)

          json_get_v2 "/api/products/#{product.id}"

          expect(json_response.commission_details.acquisition).to \
            eq "<span>10,00 €</span> jährlich für 1 Jahr ab Vertragsbeginn"
        end
      end

      context "commision payouts count is 5" do
        before do
          product.acquisition_commission_price = 10
          product.acquisition_commission_payouts_count = 5
          product.save!
        end

        it "should have commision details acquisition" do
          login_as(user, scope: :user)

          json_get_v2 "/api/products/#{product.id}"

          expect(json_response.commission_details.acquisition).to \
            eq "<span>10,00 €</span> jährlich für 5 Jahre ab Vertragsbeginn"
        end
      end
    end



    context "with a started questioannire " do
      let!(:category_questionnaire) { create(:questionnaire) }
      let!(:category) { create(:category, questionnaire: category_questionnaire) }
      let!(:category_questionnaire_plan) { create(:plan, category: category, company: create(:company)) }
      let!(:questionnaire_response) {
        create(:questionnaire_response,
                           mandate:       user.mandate,
                           questionnaire: category_questionnaire,
                           state:         "in_progress",
                           created_at:    1.year.ago)
      }

      let!(:product_with_started_questionnaire) { create(:product, plan: category_questionnaire_plan, mandate: user.mandate) }

      it "returns false for done with questionnaire flag and true for started" do
        login_as(user, scope: :user)

        json_get_v2 "/api/products/#{product_with_started_questionnaire.id}"

        expect(json_response.customer_finished_questionnaire).to be_falsy
        expect(json_response.customer_started_questionnaire).to be_truthy
      end
    end

    context "when the user has done a questionnaire" do
      # Set up all of the things
      let!(:category_questionnaire) { create(:questionnaire) }
      let!(:category) { create(:category, questionnaire: category_questionnaire) }
      let!(:questionnaire_response) {
        create(:questionnaire_response,
                           mandate:       user.mandate,
                           questionnaire: category_questionnaire,
                           state:         "completed",
                           created_at:    1.year.ago)
      }
      let!(:plan) {
        create(
          :plan,
          company:  create(:company),
          category: category
        )
      }
      let!(:opportunity) {
        create(
          :opportunity,
          source:      questionnaire_response,
          category_id: category.id,
          mandate:     user.mandate,
          state:       "created"
        )
      }
      let!(:product_with_opportunity) {
        create(
          :product,
          opportunities: [opportunity],
          mandate:       user.mandate,
          plan:          plan
        )
      }

      it "returns true for done with questionnaire flag with opp in the state created on the product" do
        login_as(user, scope: :user)

        json_get_v2 "/api/products/#{product_with_opportunity.id}"

        expect(json_response.customer_finished_questionnaire).to eq(true)
        expect(json_response.customer_started_questionnaire).to eq(false)
      end

      context "when the opportunity is in the initiation_phase" do
        before do
          product_with_opportunity.opportunities.first.update_attributes(state: "initiation_phase")
        end

        it "stil returns true for done questionnaire" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product_with_opportunity.id}"
          expect(json_response.customer_finished_questionnaire).to eq(true)
        end
      end

      context "when the opportunity is in the offer_phase" do
        before do
          product_with_opportunity.opportunities.first.update_attributes(state: "offer_phase")
        end

        it "returns false for done questionnaire" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product_with_opportunity.id}"
          expect(json_response.customer_finished_questionnaire).to eq(false)
        end
      end

      context "when the opportunity is in the completed phase" do
        before do
          product_with_opportunity.opportunities.first.update_attributes(state: "completed")
        end

        it "returns false for done questionnaire" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product_with_opportunity.id}"
          expect(json_response.customer_finished_questionnaire).to eq(false)
        end
      end

      context "when the opportunity is in the lost phase" do
        before do
          product_with_opportunity.opportunities.first.update_attributes(state: "lost")
        end

        it "returns false for done questionnaire" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product_with_opportunity.id}"
          expect(json_response.customer_finished_questionnaire).to eq(false)
        end
      end

      # This can be added again when the BE is fixed with the product id association
      # context 'when the state of the opportunity is not a questioannire response' do
      #   before do
      #     product_with_opportunity.opportunities.first.update_attributes(source: nil)
      #   end

      #   it 'returns false for done questionnaire' do
      #     login_as(user, :scope => :user)
      #     json_get_v2 "/api/products/#{product_with_opportunity.id}"
      #     expect(json_response.customer_finished_questionnaire).to eq(false)
      #   end
      # end
    end

    it "only gets the product associated with the mandate" do
      login_as(user, scope: :user)

      other_product = create(:product, mandate: create(:mandate))

      json_get_v2 "/api/products/#{other_product.id}"

      expect(response.status).to eq(404)
    end

    it "returns 401 if the user is not singed in" do
      json_get_v2 "/api/products/#{product.id}"
      expect(response.status).to eq(401)
    end

    context "Company data about the product" do
      let!(:company) { create(:company, name: "Company name one") }
      let!(:vertical) { create(:vertical) }
      let!(:category) { create(:category, vertical: vertical) }
      let!(:plan) { create(:plan, company: company, category: category) }
      let!(:product) { create(:product, mandate: user.mandate, plan: plan) }

      it "Gets the related company for the product" do
        login_as(user, scope: :user)

        json_get_v2 "/api/products/#{product.id}"

        expect(response.status).to eq(200)
        expect(json_response.company.name).to eq("Company name one")
      end
    end

    context "Category data about the product" do
      let!(:company) { create(:company) }
      let!(:vertical) { create(:vertical) }
      let!(:category) { create(:category, name: "Category name one", vertical: vertical) }
      let!(:plan) { create(:plan, company: company, category: category) }
      let!(:product_two) { create(:product, plan: plan, mandate: user.mandate) }

      it "Gets the related category for the product" do
        login_as(user, scope: :user)

        json_get_v2 "/api/products/#{product_two.id}"

        expect(response.status).to eq(200)
        expect(json_response.category.name).to eq("Category name one")
      end
    end

    context "Serving offer related data" do
      # Add an offer that is not in the offer phase
      let!(:category) { create(:category) }
      let!(:plan) { create(:plan, category: category) }
      let!(:offer_product) { create(:product, mandate: user.mandate, plan: plan) }
      let!(:opportunity_in_offer_phase) { create(:opportunity, old_product: offer_product, mandate: user.mandate, state: "offer_phase", category: category) }
      let!(:opportunity_in_creation_phase) { create(:opportunity, old_product: offer_product, mandate: user.mandate, state: "initiation_phase", category: category) }

      context "Serving the offer ID" do
        context "Offer in offer phase" do
          let!(:offer) { create(:active_offer, mandate: user.mandate, state: "active", opportunity: opportunity_in_offer_phase) }

          it "shows the offer id if the product has an offer in the offer phase" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{offer_product.id}"
            expect(json_response.offer_id).to eq(offer.id)
          end
        end

        context "Offer in creation phase" do
          let!(:offer) { create(:offer, mandate: user.mandate, state: "active", opportunity: opportunity_in_creation_phase) }
          let!(:offer_option) { create(:offer_option, product: offer_product, offer: offer) }

          it "returns nil for a product with an offer that is not in the offer phase" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{offer_product.id}"
            expect(json_response.offer_id).to be(nil)
          end

          it "returns open offer id" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{offer_product.id}"
            expect(json_response.open_offer_id).to eq(offer.id)
          end
        end

        it "returns nil for a product without an offer" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product.id}"
          expect(json_response.offer_id).to be(nil)
        end
      end

      context "Serving the offer CTA" do
        let!(:offer) { create(:active_offer, mandate: user.mandate, state: "active", opportunity: opportunity_in_offer_phase) }

        it "returns nil for oppporunity without offer" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product.id}"
          expect(json_response.offer_cta).to eq(nil)
        end

        context "Recommended offer with top cover and price" do
          before do
            offer.offer_options[0].option_type = "top_cover_and_price"
            offer.offer_options[0].save!
          end

          it "returns correct text for CTA" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{offer_product.id}"
            expect(json_response.offer_cta).to eq(I18n.t("manager.products.product.price-performance"))
          end
        end

        context "Offer with price benifit" do
          before do
            offer.offer_options[0].option_type = "top_price"
            offer.offer_options[0].save!

            # The product presenter actually checks the premiums :(
            offer.offer_options[0].product.premium_price = 20
            offer.offer_options[0].product.save!

            offer.opportunity.old_product.premium_price = 30
            offer.opportunity.old_product.save!
          end

          it "returns correct text" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{offer_product.id}"
            expect(json_response.offer_cta).to eq("120€ #{I18n.t('manager.products.product.saving')}")
          end
        end

        context "Offer without price or top cover and price" do
          before do
            offer.offer_options[0].option_type = "top_cover"
            offer.offer_options[0].save!
          end

          it "returns upgrade text by default" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{offer_product.id}"
            expect(json_response.offer_cta).to eq(I18n.t("manager.products.product.upgrade"))
          end
        end
      end
    end

    context "Working with message resource" do
      context "Return messages if there are any" do
        let!(:admin) { create(:admin) }
        let!(:message_clark) { create(:interaction_advice, topic: product, mandate: user.mandate, admin: admin, helpful: true, cta_link: "") }
        let!(:message_user) { create(:interaction_adivce_reply, topic: product, mandate: user.mandate) }

        it "returns the correct messages, when there are some on the product" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product.id}"
          expect(response.status).to eq(200)
          expect(json_response.messages.count).to eq(2)
          expect(json_response.messages[0].content).to eq("Something the admin says about the contract")
          expect(json_response.messages[1].content).to eq("Something the customer said")
        end
      end

      it "returns no messages if there are none" do
        login_as(user, scope: :user)
        json_get_v2 "/api/products/#{product.id}"
        expect(response.status).to eq(200)
        expect(json_response.messages).to eq([])
      end
    end

    context "Working with document resource" do
      let(:visible_document_type_ids) do
        [
          DocumentType.policy&.id,
          DocumentType.supplement&.id,
          DocumentType.certificate&.id,
          DocumentType.warning_letter&.id
        ].compact
      end

      before do
        DocumentType.where(id: visible_document_type_ids).update_all(authorized_customer_states: ["mandate_customer"])
      end

      context "mandate is accepted" do
        before { user.mandate.update!(state: "accepted", customer_state: "mandate_customer") }

        it "returns empty array when there are no documents for the product" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product.id}"
          expect(response.status).to eq(200)
          expect(json_response.documents).to eq([])
        end

        context "with a ton of documents" do
          let!(:product_with_documents) {
            create(
              :product,
              mandate:   user.mandate,
              documents: [
                create(:document, document_type: DocumentType.policy),
                create(:document, document_type: DocumentType.supplement),
                # The rest here should not be displayed
                create(:document, document_type: DocumentType.offer_replace),
                create(:document, document_type: DocumentType.offer_new)
              ]
            )
          }

          it "returns only the relevant docs for the product" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{product_with_documents.id}"
            expect(response.status).to eq(200)
            expect(json_response.documents.count).to eq(2)
          end
        end

        context "new documents type added check if pending is set to true" do
          it "returns only the relevent docs for the product" do
            [DocumentType.certificate, DocumentType.warning_letter].each do |document_type|
              create(
                :product,
                mandate:   user.mandate,
                documents: [create(:document, document_type: document_type)]
              )

              login_as(user, scope: :user)
              json_get_v2 "/api/products/#{Product.last.id}"
              expect(response.status).to eq(200)
              expect(json_response.documents_pending).to be(false)
            end
          end
        end
      end

      context "mandate is not accepted" do
        it "returns empty array when there are no documents for the product" do
          login_as(user, scope: :user)
          json_get_v2 "/api/products/#{product.id}"
          expect(response.status).to eq(200)
          expect(json_response.documents).to eq([])
        end

        context "with multiple documents" do
          let!(:product_with_documents) {
            create(
              :product,
              mandate:   user.mandate,
              documents: [
                create(:document, document_type: DocumentType.dimensions),
                create(:document, document_type: DocumentType.invoice)
              ]
            )
          }

          it "returns only the relevant docs for the product" do
            login_as(user, scope: :user)
            json_get_v2 "/api/products/#{product_with_documents.id}"
            expect(response.status).to eq(200)
            expect(json_response.documents.count).to eq(0)
          end
        end

        context "new documents type added check if pending is set to true" do
          it "returns only the relevant docs for the product" do
            [DocumentType.certificate, DocumentType.warning_letter].each do |document_type|
              create(
                :product,
                mandate:   user.mandate,
                documents: [create(:document, document_type: document_type)]
              )

              login_as(user, scope: :user)
              json_get_v2 "/api/products/#{Product.last.id}"
              expect(response.status).to eq(200)
              expect(json_response.documents_pending).to be(true)
            end
          end
        end
      end
    end
  end

  context "PATCH /api/products/:id/advices/:advice_id/helpful" do
    let!(:product) { create(:product, mandate: user.mandate) }
    let!(:advice) { create(:advice, topic: product, mandate: user.mandate) }

    it "sets the helpful field" do
      login_as(user, scope: :user)

      expect {
        json_patch_v2 "/api/products/#{product.id}/advices/#{advice.id}/helpful", helpful: true
        advice.reload
      }.to change { advice.helpful }
    end

    it "returns 401 if not logged in" do
      expect {
        json_patch_v2 "/api/products/#{product.id}/advices/#{advice.id}/helpful", helpful: true
        advice.reload
      }.not_to change { advice.helpful }

      expect(response.status).to eq(401)
    end

    it "returns 404 if not a advice for the user" do
      login_as(user, scope: :user)
      other_advice = create(:advice)

      expect {
        json_patch_v2 "/api/products/#{other_advice.product.id}/advices/#{other_advice.id}/helpful", helpful: true
        other_advice.reload
      }.not_to change { other_advice.helpful }

      expect(response.status).to eq(404)
    end

    it "returns 400 if helpful parameter missing" do
      login_as(user, scope: :user)

      expect {
        json_patch_v2 "/api/products/#{advice.product.id}/advices/#{advice.id}/helpful"
        advice.reload
      }.not_to change { advice.helpful }

      expect(response.status).to eq(400)
    end
  end

  context "PATCH /api/products/:id/advices/acknowledged" do
    let!(:product) { create(:product, mandate: user.mandate) }

    before do
      3.times do
        create(:advice, topic: product, mandate: user.mandate)
      end
    end

    it "sets the acknowledged field" do
      login_as(user, scope: :user)

      expect {
        json_patch_v2 "/api/products/#{product.id}/advices/acknowledged"
        product.reload
      }.to change { product.interactions.map(&:acknowledged) }
    end

    it "returns 401 if not logged in" do
      expect {
        json_patch_v2 "/api/products/#{product.id}/advices/acknowledged"
        product.reload
      }.not_to change { product.interactions.map(&:acknowledged) }

      expect(response.status).to eq(401)
    end

    it "returns 404 if not a product of the user" do
      login_as(user, scope: :user)
      other_product = create(:product)

      expect {
        json_patch_v2 "/api/products/#{other_product.id}/advices/acknowledged"
        product.reload
      }.not_to change { product.interactions.map(&:acknowledged) }

      expect(response.status).to eq(404)
    end
  end
end
