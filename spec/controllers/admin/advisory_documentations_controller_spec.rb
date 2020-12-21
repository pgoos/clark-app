# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdvisoryDocumentationsController, :integration, type: :request do
  describe "PATCH create" do
    let(:endpoint) { "/#{I18n.locale}/admin/products/#{product.id}/generate_advisory_documentation" }
    let(:product) { create(:product) }

    context "admin authenticated" do
      let(:admin) { create(:admin) }

      before { sign_in(admin) }

      context "admin with advisory_documentations permission" do
        let(:permission) { Permission.find_by(controller: "admin/advisory_documentations", action: "create") }
        let(:admin) { create(:admin, role: create(:role, permissions: [permission])) }

        context "product in order_pending or details_available state" do
          let(:opportunity) { create(:opportunity) }
          let(:offer) { create(:offer, opportunity: opportunity) }
          let(:offer_option) { create(:offer_option, offer: offer) }
          let(:category) { create(:category, :high_margin) }
          let(:plan) { create(:plan, insurance_tax: 10) }
          let(:product) do
            create(:product, :order_pending,
                   category: category, offer_option: offer_option,
                   contract_ended_at: Time.zone.now, contract_started_at: 1.year.ago, plan: plan)
          end
          let(:product_in_details_available) do
            create(:product, :details_available,
                   category: category, offer_option: offer_option,
                   contract_ended_at: Time.zone.now, contract_started_at: 1.year.ago, plan: plan)
          end
          let(:endpoint_details_available) {
            "/#{I18n.locale}/admin/products/#{product_in_details_available.id}/generate_advisory_documentation"
          }

          context "product does not have advisory documentation" do
            let(:valid_params) do
              {
                insurance_situation: Faker::Lorem.sentence,
                reason_for_consultation: Faker::Lorem.sentence,
                recommendation: Faker::Lorem.sentence,
                pros_and_cons: Faker::Lorem.sentence,
                customer_decision: Faker::Lorem.sentence
              }
            end

            it "generates advisory documentation when state is order_pending and redirects to product page" do
              expect(Domain::OrderAutomation::AdvisoryDocumentationGenerator).to receive(:new).with(
                a_hash_including(legal_information: valid_params)
              ).and_call_original
              expect(BusinessEvent).to receive(:create!).with(
                a_hash_including(metadata: valid_params)
              ).and_call_original

              patch endpoint, params: valid_params
              expect(response.status).to eq 302
              expect(response).to redirect_to admin_product_url(product.id)
              expect(product.reload).to be_advisory_documentation_present
              expect(product.business_events.find_by(action: "advisory_documentation_generated")).not_to be_blank
            end

            it "generates advisory documentation when state is details_available and redirects to product page" do
              expect(Domain::OrderAutomation::AdvisoryDocumentationGenerator).to receive(:new).with(
                a_hash_including(legal_information: valid_params)
              ).and_call_original
              expect(BusinessEvent).to receive(:create!).with(
                a_hash_including(metadata: valid_params)
              ).and_call_original

              patch endpoint_details_available, params: valid_params
              expect(response.status).to eq 302
              expect(response).to redirect_to admin_product_url(product_in_details_available.id)
              expect(product_in_details_available.reload).to be_advisory_documentation_present
              expect(
                product_in_details_available.business_events.find_by(
                  action: "advisory_documentation_generated"
                )
              ).not_to be_blank
            end

            context "offer sent via email" do
              let(:product) do
                create(:product, :order_pending,
                       category: category,
                       contract_ended_at: Time.zone.now,
                       contract_started_at: 1.year.ago,
                       plan: plan)
              end

              before do
                opportunity.update!(sold_product_id: product.id)
              end

              it "generates advisory documentation and redirects to product page" do
                expect(Domain::OrderAutomation::AdvisoryDocumentationGenerator).to receive(:new).with(
                  a_hash_including(legal_information: valid_params)
                ).and_call_original
                expect(BusinessEvent).to receive(:create!).with(
                  a_hash_including(metadata: valid_params)
                ).and_call_original

                patch endpoint, params: valid_params
                expect(response.status).to eq 302
                expect(response).to redirect_to admin_product_url(product.id)
                expect(product.reload).to be_advisory_documentation_present
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).not_to be_blank
              end
            end

            context "missing recommendation" do
              it "does not generate advisory documentation" do
                patch endpoint, params: valid_params.merge(recommendation: "")
                expect(response.status).to eq 422
                expect(json_response["errors"]["recommendation"]).to eq(
                  I18n.t("admin.products.documents.advisory_documentation.errors.missing.recommendation")
                )
                expect(product.reload).not_to be_advisory_documentation_present
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).to be_blank
              end
            end

            context "missing insurance situation" do
              it "does not generate advisory documentation" do
                patch endpoint, params: valid_params.merge(insurance_situation: "")
                expect(response.status).to eq 422
                expect(json_response["errors"]["insurance_situation"]).to eq(
                  I18n.t("admin.products.documents.advisory_documentation.errors.missing.insurance_situation")
                )
                expect(product.reload).not_to be_advisory_documentation_present
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).to be_blank
              end
            end

            context "missing customer decision" do
              it "does not generate advisory documentation" do
                patch endpoint, params: valid_params.merge(customer_decision: "")
                expect(response.status).to eq 422
                expect(json_response["errors"]["customer_decision"]).to eq(
                  I18n.t("admin.products.documents.advisory_documentation.errors.missing.customer_decision")
                )
                expect(product.reload).not_to be_advisory_documentation_present
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).to be_blank
              end
            end

            context "missing pros and cons" do
              it "does not generate advisory documentation" do
                patch endpoint, params: valid_params.merge(pros_and_cons: "")
                expect(response.status).to eq 422
                expect(json_response["errors"]["pros_and_cons"]).to eq(
                  I18n.t("admin.products.documents.advisory_documentation.errors.missing.pros_and_cons")
                )
                expect(product.reload).not_to be_advisory_documentation_present
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).to be_blank
              end
            end

            context "missing contract_started_at in product" do
              let(:product) do
                create(:product, :order_pending,
                       category: category, offer_option: offer_option,
                       contract_ended_at: Time.zone.now, contract_started_at: nil, plan: plan)
              end

              it "does not generate advisory documentation" do
                patch endpoint, params: valid_params.merge(recomendation_missing: "")
                expect(response.status).to eq 422
                expect(json_response["errors"]["contract_started_at"]).to eq(
                  I18n.t("admin.products.documents.advisory_documentation.errors.missing.contract_started_at")
                )
                expect(product.reload).not_to be_advisory_documentation_present
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).to be_blank
              end
            end

            context "generic error during business event creation" do
              it "does not generate advisory documentation" do
                expect(BusinessEvent).to receive(:create!).with(
                  a_hash_including(metadata: valid_params)
                ).and_raise(StandardError.new("some reason"))

                patch endpoint, params: valid_params
                expect(response.status).to eq 422
                expect(product.reload).not_to be_advisory_documentation_present
                expect(json_response["errors"]["general"]).to eq("business event creation failed: some reason")
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).to be_blank
              end
            end

            context "generic error during advisory document creation" do
              it "does not generate advisory documenation" do
                expect(Domain::OrderAutomation::AdvisoryDocumentationGenerator).to receive(:new).and_raise(
                  StandardError.new("some reason")
                )
                patch endpoint, params: valid_params
                expect(response.status).to eq 422
                expect(json_response["errors"]["general"]).to eq("advisory documentation creation failed: some reason")
                expect(product.reload).not_to be_advisory_documentation_present
                expect(product.business_events.find_by(action: "advisory_documentation_generated")).to be_blank
              end
            end
          end

          context "product already has advisory documentation" do
            before { product.documents << create(:document, :advisory_documentation) }

            it "returns error" do
              patch endpoint
              expect(response.status).to eq 422
              expect(json_response["errors"]["general"]).to eq(
                I18n.t("admin.products.documents.advisory_documentation.errors.advisory_documentation_present")
              )
            end
          end
        end

        context "product not in order_pending state" do
          let(:product) { create(:product, :ordered) }

          it "returns error" do
            patch endpoint
            expect(response.status).to eq 422
            expect(json_response["errors"]["general"]).to eq(
              I18n.t("admin.products.documents.advisory_documentation.errors.wrong_product_state")
            )
          end
        end
      end

      context "admin without advisory_documentations permission" do
        it "redirects to main opsui page" do
          patch endpoint
          expect(response.status).to eq 302
          expect(response).to redirect_to admin_root_url
        end
      end
    end

    context "admin unauthenticated" do
      it "redirects to login page" do
        patch endpoint
        expect(response.status).to eq 302
      end
    end
  end
end
