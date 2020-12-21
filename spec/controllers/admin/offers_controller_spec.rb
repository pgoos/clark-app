# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::OffersController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/offers")) }
  let(:admin) { create(:admin, role: role) }
  let(:offer) { create(:offer_with_opportunity_in_initiation_phase) }

  describe "PATCH update" do
    let(:user)         { create(:user, :with_mandate) }
    let(:valid_params) { {insurance_comparison_id: ""} }

    before do
      pdf = PdfGenerator::Generator.pdf_by_template(
        "pdf_generator/comparison_document", offer: offer
      )
      offer.documents.create!(document_type_id: DocumentType.offer_new.id, asset: pdf)
      login_admin(admin)
    end

    it "deletes the old comparison document" do
      old_comparison_document = offer.documents.find_by(document_type: DocumentType.offer_new)

      patch :update, params: {locale:         I18n.locale,
                              opportunity_id: offer.opportunity.id,
                              id:             offer.id,
                              offer:          valid_params}

      expect { old_comparison_document.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end

    it "create a new comparison document" do
      pdf_double = n_double("pdf_double")

      expect(PdfGenerator::Generator).to receive(:pdf_by_template)
        .with("pdf_generator/comparison_document", offer: offer)
        .and_return(pdf_double)

      patch :update, params: {locale:         I18n.locale,
                              opportunity_id: offer.opportunity.id,
                              id:             offer.id,
                              offer:          valid_params}
    end
  end

  describe "GET single_column_new" do
    context "admin authenticated" do
      before { login_admin(admin) }

      it "returns 200" do
        get :single_column_new, params: { locale: I18n.locale, opportunity_id: offer.opportunity.id }
        expect(response.status).to eq 200
      end
    end

    context "admin not authenticated" do
      it "redirects to login page" do
        get :single_column_new, params: { locale: I18n.locale, opportunity_id: offer.opportunity.id }
        expect(response.status).to eq 302
      end
    end
  end

  describe "POST accept_offer" do
    let!(:customer) { create(:customer, :prospect) }
    let(:mandate) { Mandate.find(customer.id) }
    let(:opportunity) { create(:opportunity_with_offer, mandate: mandate, state: :offer_phase) }
    let(:product) { opportunity.offer.offer_options.first.product }

    context "authorized" do
      before { login_admin(admin) }

      context "valid params" do
        it "triggers accept_offer_complete_opportunity interactor" do
          patch :accept_offer, params: {
            locale:         I18n.locale,
            opportunity_id: opportunity.id,
            contract_id:    product.id
          }

          # Offer moved to the 'accepted' state
          expect(opportunity.reload.offer).to be_accepted
          expect(response).to redirect_to(complete_admin_opportunity_path(opportunity))
        end
      end

      context "interactor returns error" do
        let(:error) { "Some error description" }

        it "returns error in flash alert" do
          expect(::Sales).to receive(:accept_offer_for_customer)
            .with(opportunity.id, product.id)
            .and_return(double("result", successful?: false, errors: [error]))

          patch :accept_offer, params: {
            locale:         I18n.locale,
            opportunity_id: opportunity.id,
            contract_id:    product.id
          }

          expect(flash[:alert]).to eq [error]
          expect(response).to redirect_to(admin_opportunity_path(opportunity))
        end
      end
    end

    context "unauthorized" do
      it "redirects to login page" do
        patch :accept_offer, params: {
          locale:         I18n.locale,
          opportunity_id: opportunity.id,
          contract_id:    product.id
        }
        expect(response.status).to eq 302
      end
    end
  end
end
