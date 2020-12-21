# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PaybackTransactionsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/payback_transactions")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET failed" do
    let(:subject) { get :failed, params: {locale: I18n.locale} }

    context "at least 1 failed payback transaction exists" do
      let!(:failed_payback_transaction) do
        create(
          :payback_transaction, :with_inquiry_category, :book,
          state: :failed,
          locked_until: Time.zone.now + 3.hours
        )
      end

      let!(:payback_transaction_with_later_success) do
        create(
          :payback_transaction, :with_inquiry_category, :book,
          state: :failed,
          locked_until: Time.zone.now + 3.hours,
          receipt_no: "TEST_REC"
        )
      end

      let!(:successful_payback_transaction) do
        create(
          :payback_transaction, :with_inquiry_category, :book,
          state: :completed,
          locked_until: Time.zone.now + 3.hours,
          receipt_no: "TEST_REC"
        )
      end

      it "responds with success and assigns only failed transactions with no subsequent success" do
        subject
        expect(response).to have_http_status(:ok)
        expect(assigns(:transactions).map(&:id)).to eq([failed_payback_transaction.id])
      end
    end

    context "no failed payback transactions exist" do
      it "responds with success and assigns no transactions" do
        subject
        expect(response).to have_http_status(:ok)
        expect(assigns(:transactions).map(&:id)).to eq([])
      end
    end
  end

  describe "POST reschedule" do
    subject {
      post :reschedule,
           params: {
             locale: I18n.locale,
             id: payback_transaction.id
           }
    }

    let(:payback_transaction) do
      build_stubbed(
        :payback_transaction, :with_inquiry_category, :book,
        state: :failed,
        locked_until: Time.zone.now + 3.hours
      )
    end

    let(:reschedule_failed_transaction_interactor) do
      instance_double(
        Payback::Interactors::RescheduleFailedTransaction,
        call: reschedule_response
      )
    end

    before do
      allow(Payback::Container)
        .to receive(:resolve)
        .with("interactors.reschedule_failed_transaction")
        .and_return(reschedule_failed_transaction_interactor)
    end

    context "transaction reschedule succeeds" do
      let(:reschedule_response) {
        instance_double(
          Utils::Interactor::Result,
          success?: true
        )
      }

      it "should flash success" do
        subject
        expect(flash[:notice]).to eq(I18n.t("admin.marketing.payback.reschedule_successful"))
      end

      it "redirects to the view" do
        expect(subject).to redirect_to(failed_admin_payback_transactions_path)
      end
    end

    context "transaction reschedule fails" do
      let(:errors) { %w[error1 error2] }
      let(:reschedule_response) {
        instance_double(
          Utils::Interactor::Result,
          success?: false,
          errors: errors
        )
      }

      it "should flash any errors" do
        subject
        expect(flash[:alert]).to eq(errors.join("<br>"))
      end

      it "redirects to the view" do
        expect(subject).to redirect_to(failed_admin_payback_transactions_path)
      end
    end
  end
end
