# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::RetirementProductsController, :integration, type: :controller do
  let(:admin) { create :super_admin }

  before { login_admin(admin) }

  describe "PATCH /products/:product_id/retirement_product/request_information" do
    let(:mailer) { double(:mailer, deliver_later: nil) }
    let(:product) { create :product }
    let!(:retirement_product) { create :retirement_product, :created, :state, product: product }

    before do
      allow(RetirementProductMailer).to \
        receive(:information_required).and_return mailer
      allow(OutboundChannels::Messenger::TransactionalMessenger).to \
        receive(:retirement_product_information_requested)
    end

    it "updates state and saves requested information to metadata" do
      patch :request_information,
            params: {
              locale: I18n.locale,
              product_id: product.id,
              retirement_product: {
                requested_information: %w[guaranteed_capital]
              }
            }

      retirement_product.reload
      expect(retirement_product).to be_information_required
      expect(retirement_product.requested_information).to eq %w[guaranteed_capital]
      expect(retirement_product.information_requested_at).to be_present
    end

    it "notifies customer" do
      expect(mailer).to receive(:deliver_later)
      expect(OutboundChannels::Messenger::TransactionalMessenger).to \
        receive(:retirement_product_information_requested)

      patch :request_information,
            params: {
              locale: I18n.locale,
              product_id: product.id,
              retirement_product: {
                requested_information: %w[guaranteed_capital]
              }
            }
    end

    context "when this is no requested_information" do
      it "does not notify customer" do
        expect(mailer).not_to receive(:deliver_later)
        expect(OutboundChannels::Messenger::TransactionalMessenger).not_to \
          receive(:retirement_product_information_requested)

        patch :request_information,
              params: {
                locale: I18n.locale,
                product_id: product.id,
                retirement_product: {requested_information: []}
              }

        expect(retirement_product.reload).to be_information_required
      end
    end
  end

  describe "#initialize_retirement" do
    let!(:product) { create :product }

    before { request.env["HTTP_REFERER"] = admin_product_path(product) }

    context "with valid" do
      let(:product) { create :product, :retirement_state_category }

      context "when retirement is enabled" do
        before do
          allow(Domain::Retirement::RetirementProcess).to receive(:retirement_enabled?)
            .and_return(true)
        end

        it "should set @retirement_product" do
          get :edit, params: {locale: I18n.locale, product_id: product.id}
          expect(assigns(:retirement_product)).to eq(product.retirement_product)
        end
      end

      context "when retirement is not enabled" do
        before do
          allow(Domain::Retirement::RetirementProcess).to receive(:retirement_enabled?)
            .and_return(false)
        end

        it "redirects to product page" do
          get :edit, params: {locale: I18n.locale, product_id: product.id}
          expect(controller).to redirect_to admin_product_path(product)
        end
      end
    end

    context "with invalid" do
      before do
        allow(Domain::Retirement::RetirementProcess).to receive(:retirement_enabled?)
          .and_return(true)
        allow(Domain::Retirement::RetirementProcess).to receive(:setup_retirement_product)
          .with(anything).and_return(product).and_raise(ActiveRecord::RecordInvalid)
      end

      it "should rescue from ActiveRecord::InvalidRecord error" do
        get :edit, params: {locale: I18n.locale, product_id: product.id}
        expect(controller).to set_flash[:alert]
      end
    end
  end
end
