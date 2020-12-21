# frozen_string_literal: true

require "rails_helper"
require "support/settings_helpers"

RSpec.describe ClarkAPI::V2::Offer, :integration do
  let(:user) { create(:user, mandate: create(:mandate)) }
  before do
    allow(Features).to receive(:active?).and_call_original
  end

  context "PATCH /api/offer/:id/send_offer_email" do
    let(:opportunity) { create(:opportunity_with_offer_in_creation, mandate: user.mandate) }

    it "returns 200 if able to send out the email" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/offer/#{opportunity.offer.id}/send_offer_email"

      expect(json_response.success).to eq(true)
      expect(response.status).to eq(200)
    end

    it "returns 200 if the offer is already activated" do
      login_as(user, scope: :user)
      opportunity.offer.update_attributes(state: "active")

      json_patch_v2 "/api/offer/#{opportunity.offer.id}/send_offer_email"

      expect(json_response.success).to eq(true)
      expect(response.status).to eq(200)
    end

    it "returns 404 if could not find the offer" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/offer/99999999999999999999/send_offer_email"

      expect(response.status).to eq(404)
    end

    it "returns 401 if the user is not singed in" do
      json_patch_v2 "/api/offer/#{opportunity.offer.id}/send_offer_email"
      expect(response.status).to eq(401)
    end

    it "returns 500 if the offer is not in the in_creation or active" do
      login_as(user, scope: :user)
      opportunity.offer.update_attributes(state: "expired")

      json_patch_v2 "/api/offer/#{opportunity.offer.id}/send_offer_email"

      expect(json_response.success).to eq(false)
      expect(response.status).to eq(500)
    end
  end

  context "GET /api/offer/:id" do
    let(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

    it "gets the offer associated with the mandate" do
      login_as(user, scope: :user)

      json_get_v2 "/api/offer/#{opportunity.offer.id}"

      expect(response.status).to eq(200)
    end

    context "with data in the offer" do
      include ActionView::Helpers::TextHelper
      include SettingsHelpers

      let(:custom_note) { "Hallo Kunde\ndas ist ein Test\n\nFoo Bar" }
      let(:formatted_default_note) { simple_format(default_note) }
      let(:formatted_custom_note) { simple_format(custom_note) }

      context "when offer is automated" do
        let(:automated) { true }
        let(:default_note) do
          I18n.t(
            "grape.api.v2.offer_automation.note_to_customer",
            email: opportunity.admin.email,
            phone_number: I18n.t("phone_number")
          )
        end

        before do
          opportunity.mark_as_automated
          save_settings("offer_automation.note_to_customer.attach_default")
          attach_default
          login_as(user, scope: :user)
          opportunity.offer.update(note_to_customer: custom_note)
          json_get_v2 "/api/offer/#{opportunity.offer.id}"
        end

        after { restore_settings }

        context "when setting attach_default is false" do
          let(:attach_default) { Settings.offer_automation.note_to_customer.attach_default = false }

          after do
            Settings.reload!
          end

          it "returns custom note" do
            expect(json_response.note_to_customer).to eq(formatted_custom_note)
            expect(json_response.is_automated).to be_truthy
          end
        end

        context "when setting attach_default is true" do
          let(:attach_default) { Settings.offer_automation.note_to_customer.attach_default = true }

          after do
            Settings.reload!
          end

          it "returns custom note with default note added" do
            expect(json_response.note_to_customer).to eq("#{formatted_custom_note}\n\n#{formatted_default_note}")
            expect(json_response.is_automated).to be_truthy
          end
        end
      end

      context "coverages" do
        let(:category) { opportunity.category }
        let(:offer_option) { opportunity.offer.offer_options.first }
        let(:product) { offer_option.product }

        let(:coverages) { { coverage_key => coverage_value } }

        before do
          category.coverage_features = coverage_features
          category.save!
          plan = product.plan
          plan.category = category
          plan.save!
          product.reload
          product.coverages = coverages
          product.save!

          login_as(user, scope: :user)

          json_get_v2 "/api/offer/#{opportunity.offer.id}"
          @response_option = json_response["options"].find { |option| option["id"] == offer_option.id }
        end

        context "coverages" do
          let(:coverage_key) { "int_slndsfnthltnnrhlbrp_af1614" }
          let(:coverage_value) { ValueTypes::Int.new(-1) }
          let(:coverage_features) do
            [CoverageFeature.new(identifier: coverage_key, value_type: "Int", name: "Int coverage", definition: "test")]
          end

          it "returns coverages with formatted values in the response" do
            expect(@response_option["product"]["coverages"][coverage_key]).to eq(I18n.t("coverage-features.undefined"))
          end
        end

        context "detailed_coverages" do
          let(:coverage_key) { "dckng9ff71af780194301" }
          let(:coverage_value) { ValueTypes::Money.new(1_000_000, "EUR") }
          let(:coverage_features) do
            [CoverageFeature.new(identifier: coverage_key, value_type: "Money", name: "P", definition: "sample")]
          end

          it "returns detailed_coverages in the response" do
            detailed_coverage = @response_option["product"]["detailed_coverages"]
            expect(detailed_coverage[coverage_key]["value"]).to eq(coverage_value.value)
            expect(detailed_coverage[coverage_key]["currency"]).to eq(coverage_value.currency)
          end
        end
      end

      context "plan and offer documents" do
        let(:request_url) { "/api/offer/#{opportunity.offer.id}" }
        let(:offer_option) { opportunity.offer.offer_options.first }
        let(:plan) { offer_option.product.plan }
        let(:response_option) { json_response["options"].find { |option| option["id"] == offer_option.id } }

        before { login_as(user, scope: :user) }

        context "when no document available" do
          it "returns empty array" do
            json_get_v2 request_url
            expect(response_option["product"]["plan_documents"]).to eq([])
            expect(response_option["product"]["offer_documents"]).to eq([])
          end
        end

        context "when documents are present" do
          let(:parent_plan) { create(:parent_plan) }
          let(:general_insurance_conditions_document_type) { DocumentType.general_insurance_conditions }
          let(:consultation_waives_document_type) { DocumentType.consultation_waives }
          let(:vvg_information_package) { DocumentType.vvg_information_package }
          let(:supporting_offer_documents) { DocumentType.supporting_offer_documents }

          let!(:general_insurance_conditions_document) do
            create(:document, document_type: general_insurance_conditions_document_type, documentable: parent_plan)
          end

          let!(:consultation_waives_document) do
            create(:document, document_type: consultation_waives_document_type, documentable: parent_plan)
          end

          let!(:offer_documents) do
            [
              create(:document, document_type: vvg_information_package, documentable: offer_option.product),
              create(:document, document_type: supporting_offer_documents, documentable: offer_option.product)
            ]
          end

          before do
            plan.update!(parent_plan: parent_plan)
            opportunity.mandate.update!(customer_state: "self_service")
          end

          it "returns correct documents" do
            json_get_v2 request_url

            # it returns plan documents
            response_documents = response_option["product"]["plan_documents"]

            expect(response_documents.length).to eq(2)

            general_insurance_conditions_response =
              response_documents.find do |doc|
                doc.dig(:document_type, :key) == general_insurance_conditions_document_type.key
              end

            consultation_waives_response =
              response_documents.find do |doc|
                doc.dig(:document_type, :key) == consultation_waives_document_type.key
              end

            expect(general_insurance_conditions_response["id"]).to eq(general_insurance_conditions_document.id)
            expect(general_insurance_conditions_response["url"]).not_to be_nil
            expect(general_insurance_conditions_response["document_type"]["name"])
              .to eq(general_insurance_conditions_document_type.name)

            expect(consultation_waives_response["id"]).to eq(consultation_waives_document.id)
            expect(consultation_waives_response["url"]).not_to be_nil
            expect(consultation_waives_response["document_type"]["name"])
              .to eq(consultation_waives_document_type.name)

            # it returns offer documents
            documents = response_option["product"]["offer_documents"]
            expect(documents.length).to eq(2)

            vvg_information_package_response = documents.find do |doc|
              doc.dig(:document_type, :key) == vvg_information_package.key
            end

            supporting_offer_documents_response = documents.find do |doc|
              doc.dig(:document_type, :key) == supporting_offer_documents.key
            end

            expect(vvg_information_package_response["id"]).to eq(offer_documents[0].id)
            expect(vvg_information_package_response["url"]).not_to be_nil
            expect(vvg_information_package_response["document_type"]["name"]).to eq(vvg_information_package.name)
            expect(supporting_offer_documents_response["id"]).to eq(offer_documents[1].id)
            expect(supporting_offer_documents_response["url"]).not_to be_nil
            expect(supporting_offer_documents_response["document_type"]["name"]).to eq(supporting_offer_documents.name)
          end
        end
      end

      context "when offer isn't automated" do
        let(:default_note) do
          I18n.t(
            "grape.api.v2.offer.note_to_customer",
            email: opportunity.admin.email,
            phone_number: I18n.t("phone_number")
          )
        end

        before do
          save_settings("offer.note_to_customer.custom_or_default")
          custom_or_default
          login_as(user, scope: :user)
          opportunity.offer.update(note_to_customer: custom_note)
          json_get_v2 "/api/offer/#{opportunity.offer.id}"
        end

        after { restore_settings }

        context "when setting custom_or_default is false" do
          let(:custom_or_default) { Settings.offer.note_to_customer.custom_or_default = false }

          after do
            Settings.reload!
          end

          it "returns custom note with default note added" do
            expect(json_response.note_to_customer).to eq("#{formatted_custom_note}\n\n#{formatted_default_note}")
            expect(json_response.is_automated).to be_falsey
          end
        end

        context "when setting custom_or_default is true" do
          let(:custom_or_default) { Settings.offer.note_to_customer.custom_or_default = true }

          after do
            Settings.reload!
          end

          it "returns custom note" do
            expect(json_response.note_to_customer).to eq(formatted_custom_note)
            expect(json_response.is_automated).to be_falsey
          end

          context "when no note_to_customer is nil" do
            let(:custom_note) { nil }

            it "returns nil" do
              expect(json_response.note_to_customer).to be_nil
              expect(json_response.is_automated).to be_falsey
            end
          end
        end
      end

      describe "show_labels" do
        before do
          save_settings("offer.label_pivot_date")
          allow(Features).to receive(:active?).with(Features::OFFER_VIEW_LABELS).and_return(feature_switch)
          allow(Features).to receive(:active?).with(Features::API_NOTIFY_PARTNERS).and_return(false)
          Settings.offer.label_pivot_date = pivot_date.to_s
          login_as(user, scope: :user)
          json_get_v2 "/api/offer/#{opportunity.offer.id}"
        end

        after { Settings.reload! }

        context "OFFER_VIEW_LABELS feature is ON" do
          let(:feature_switch) { true }

          context "manual offer" do
            context "pivot date > offer creation date" do
              let(:pivot_date) { 1.week.from_now }

              it "returns false" do
                expect(json_response.show_labels).to be_falsey
              end
            end

            context "pivot date < offer creation date" do
              let(:pivot_date) { 1.week.ago }

              it "returns true" do
                expect(json_response.show_labels).to be_truthy
              end
            end
          end

          context "offer generated from offer rule" do
            let(:opportunity) do
              create(:opportunity_with_offer, mandate: user.mandate).tap do |opportunity|
                opportunity.offer.update!(offer_rule: create(:offer_rule, activated_at: Date.today))
              end
            end

            context "pivot date > offer rule activation date" do
              let(:pivot_date) { 1.week.from_now }

              it "returns false" do
                expect(json_response.show_labels).to be_falsey
              end
            end

            context "pivot date < offer rule activation date" do
              let(:pivot_date) { 1.week.ago }

              it "returns true" do
                expect(json_response.show_labels).to be_truthy
              end
            end
          end
        end

        context "OFFER_VIEW_LABELS feature is OFF" do
          let(:feature_switch) { false }

          context "manual offer" do
            context "pivot date > offer creation date" do
              let(:pivot_date) { 1.week.from_now }

              it "returns false" do
                expect(json_response.show_labels).to be_falsey
              end
            end

            context "pivot date < offer creation date" do
              let(:pivot_date) { 1.week.ago }

              it "returns false" do
                expect(json_response.show_labels).to be_falsey
              end
            end
          end

          context "offer generated from offer rule" do
            let(:opportunity) do
              create(:opportunity_with_offer, mandate: user.mandate).tap do |opportunity|
                opportunity.offer.update!(offer_rule: create(:offer_rule, activated_at: Date.today))
              end
            end

            context "pivot date > offer rule activation date" do
              let(:pivot_date) { 1.week.from_now }

              it "returns false" do
                expect(json_response.show_labels).to be_falsey
              end
            end

            context "pivot date < offer rule activation date" do
              let(:pivot_date) { 1.week.ago }

              it "returns false" do
                expect(json_response.show_labels).to be_falsey
              end
            end
          end
        end
      end

      context "exposing category" do
        let(:request_url) { "/api/offer/#{opportunity.offer.id}" }
        let(:margin_level) { "medium" }

        before do
          login_as(user, scope: :user)
          opportunity.offer.category.update_attributes(margin_level: "medium")
        end

        context "for non GKV" do
          it "returns margin_level" do
            json_get_v2 request_url

            category = json_response["category"]
            expect(category["name"]).to eq(opportunity.offer.category.name)
            expect(category["ident"]).to eq(opportunity.offer.category.ident)
            expect(category["margin_level"]).to eq(margin_level)
          end
        end

        context "for GKV" do
          let(:category_gkv) { create(:category_gkv, margin_level: "high") }

          it "does not returns margin_level" do
            opportunity.update_attributes(category_id: category_gkv.id)
            json_get_v2 request_url

            category = json_response["category"]
            expect(category["name"]).to eq(opportunity.offer.category.name)
            expect(category["ident"]).to eq(opportunity.offer.category.ident)
            expect(category).not_to have_key("margin_level")
          end
        end
      end
    end

    it "only gets the offer associated with the mandate" do
      login_as(user, scope: :user)

      other_opportunity = create(:opportunity_with_offer, mandate: create(:mandate))

      json_get_v2 "/api/offer/#{other_opportunity.offer.id}"

      expect(response.status).to eq(404)
    end

    it "returns 401 if the user is not singed in" do
      json_get_v2 "/api/offer/#{opportunity.offer.id}"
      expect(response.status).to eq(401)
    end

    it "returns 200 regardless of the state of the offer" do
      login_as(user, scope: :user)
      opportunity.offer.update(state: "rejected")

      json_get_v2 "/api/offer/#{opportunity.offer.id}"

      expect(response.status).to eq(200)
    end

    it "returns correct state of the offer" do
      login_as(user, scope: :user)
      json_get_v2 "/api/offer/#{opportunity.offer.id}"

      expect(json_response.state).to eq(opportunity.offer.state)
    end
  end

  context "PATCH /api/offer/:id/mark_as_read" do
    subject(:request_and_reload) do
      json_patch_v2 "/api/offer/#{opportunity.offer.id}/mark_as_read"
      offer_sent_interaction.reload
    end

    let(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }
    let!(:offer_sent_interaction) do
      Interaction::SentOffer.create!(
        mandate: user.mandate, admin: opportunity.admin, topic: opportunity,
        offer_id: opportunity.offer_id, content: "Offer sent"
      )
    end

    before do
      login_as(user, scope: :user)
    end

    it "marks the OfferSentInteraction as read" do
      expect { request_and_reload }.to change(offer_sent_interaction, :acknowledged).from(false).to(true)
      expect(response.status).to eq(200)
    end
  end

  context "PATCH /api/offer/:id/accept/:product_id" do
    let(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

    it "accepts a product from an offer" do
      login_as(user, scope: :user)

      product = opportunity.offer.offer_options.first.product

      json_patch_v2 "/api/offer/#{opportunity.offer.id}/accept/#{product.id}"

      product.reload
      opportunity.reload

      expect(response.status).to eq(200)
      expect(opportunity.offer.state).to eq("accepted")
      expect(product.state).to eq("order_pending")
      expect(opportunity.offer.offer_options.second.product.state).to eq("canceled")
      expect(opportunity.offer.offer_options.third.product.state).to eq("canceled")
    end

    it "only accept a product if it is associated with a associated offer" do
      login_as(user, scope: :user)

      other_opportunity = create(:opportunity_with_offer, mandate: create(:mandate))
      product = other_opportunity.offer.offer_options.first.product

      json_patch_v2 "/api/offer/#{other_opportunity.offer.id}/accept/#{product.id}"

      product.reload

      expect(response.status).to eq(404)
      expect(product.mandate_id).to eq(nil)
    end

    it "updates the send mail option if provided" do
      login_as(user, scope: :user)
      send_application_via_email = true
      offer = opportunity.offer
      product = offer.offer_options.first.product

      json_patch_v2 "/api/offer/#{offer.id}/accept/#{product.id}", send_email: send_application_via_email
      offer.reload
      expect(response.status).to eq(200)
      expect(offer.send_application_via_email).to eq(send_application_via_email)
    end

    it "returns 401 if the user is not singed in" do
      json_patch_v2 "/api/offer/#{opportunity.offer.id}/accept/#{opportunity.offer.offer_options.first.product_id}"
      expect(response.status).to eq(401)
    end

    it "returns 410 if the offer is not in the active state" do
      login_as(user, scope: :user)
      opportunity.offer.update_attributes(state: "rejected")

      product = opportunity.offer.offer_options.first.product

      json_patch_v2 "/api/offer/#{opportunity.offer.id}/accept/#{product.id}"

      expect(response.status).to eq(410)
    end
  end

  context "POST /api/offer/:id/reject" do
    let(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

    it "reject an offer and store the reason" do
      login_as(user, scope: :user)

      params = {mandate_id: user.mandate.id, reasons: "some reason."}
      json_post_v2 "/api/offer/#{opportunity.offer.id}/reject", params

      offer = opportunity.offer.reload
      expect(response.status).to eq(201)
      expect(offer.state).to eq("rejected")
      expect(offer.rejection_reason).to eq("some reason.")
    end
  end

  context "PATCH /api/offer/:id/reject" do
    let(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

    it "reject a offer" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/offer/#{opportunity.offer.id}/reject"

      opportunity.reload

      expect(response.status).to eq(200)
      expect(opportunity.offer.state).to eq("rejected")
      expect(opportunity.offer.offer_options.first.product.state).to eq("canceled")
      expect(opportunity.offer.offer_options.second.product.state).to eq("canceled")
      expect(opportunity.offer.offer_options.third.product.state).to eq("canceled")
    end

    it "only rejects a offer if it is associated with a associated mandate" do
      login_as(user, scope: :user)

      other_opportunity = create(:opportunity_with_offer, mandate: create(:mandate))

      json_patch_v2 "/api/offer/#{other_opportunity.offer.id}/reject"

      expect(response.status).to eq(404)
      expect(opportunity.offer.state).to eq("active")
    end

    it "returns 401 if the user is not singed in" do
      json_patch_v2 "/api/offer/#{opportunity.offer.id}/reject"
      expect(response.status).to eq(401)
    end

    it "returns 410 if the offer is not in the active state" do
      login_as(user, scope: :user)
      opportunity.offer.update_attributes(state: "rejected")

      json_patch_v2 "/api/offer/#{opportunity.offer.id}/reject"

      expect(response.status).to eq(410)
    end
  end

  context "PATCH /api/offer/:id/select_as_active" do
    subject { json_patch_v2 "/api/offer/#{offer.id}/select_as_active" }

    let(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }
    let(:offer) { opportunity.offer }

    context "when logged in as user" do
      before { login_as(user, scope: :user) }

      it "sets the active_offer_selected flag of the offer to true" do
        expect { subject }.to change { offer.reload.active_offer_selected }.from(false).to(true)
        expect(response.status).to eq(200)
      end

      context "when offer is already active_offer_selected" do
        before { offer.update_attributes(active_offer_selected: true) }

        it "does not change the active_offer_selected flag" do
          expect { subject }.not_to(change { offer.reload.active_offer_selected })
          expect(response.status).to eq(200)
        end
      end
    end

    context "when unauthenticated" do
      it "does not change active_offer_selected" do
        expect { subject }.not_to(change { offer.reload.active_offer_selected })
        expect(response.status).to eq(401)
      end
    end
  end
end
