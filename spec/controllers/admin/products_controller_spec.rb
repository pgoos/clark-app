# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ProductsController, :integration, type: :controller do
  let!(:bot_admin) { create(:admin) }
  let!(:product) { create(:product) }
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/products")) }
  let(:admin) { create(:admin, role: role) }
  let(:active_mandate) { create(:mandate) }
  let(:revoked_mandate) { create(:mandate, :revoked) }

  before do
    allow(Features).to receive(:active?).and_call_original
    login_admin(admin)
  end

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Filter
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Actions
  # ---------------------------------------------------------------------------------------
  describe "GET index" do
    context "when followup with revoked mandate exists" do
      let!(:product_with_active_mandate) { product }
      let!(:product_with_revoked_mandate) { create(:product, mandate: revoked_mandate) }

      context "when admin does not have permission to see revoked mandates" do
        it "does not show revoked product" do
          get :index, params: { locale: I18n.locale }

          expect(response).to have_http_status(:ok)
          expect(assigns(:products).pluck(:id)).to eq([product_with_active_mandate.id])
        end
      end

      context "when admin does have permission to see revoked mandates" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "does show revoked product" do
          get :index, params: { locale: I18n.locale }

          expect(response).to have_http_status(:ok)
          expect(
            assigns(:products).pluck(:id)
          ).to eq([product_with_revoked_mandate.id, product_with_active_mandate.id])
        end
      end
    end
  end

  describe "PATCH send_offered_product_available_email" do
    let!(:user) { create(:user, :with_mandate) }

    it "sends an email" do
      mail_double = n_double("mail_double")
      expect(mail_double).to receive(:deliver_now)
      expect(ProductMailer).to receive(:offered_product_available).with(product)
                                                                  .and_return(mail_double)
      patch :send_offered_product_available_email, params: {locale: I18n.locale, id: product.id}
    end

    context "when user has devices allowing push" do
      let!(:device) { create(:device) }

      before { user.devices << device }

      it "sends a push notification to the user if the user has devices that allow push" do
        device_double = double(Device, human_name: "some iPhone")
        expect(PushService).to receive(:send_transactional_push)
          .with(product.mandate, "offered_product_available", product, product_id: product.id)
          .and_return(device_double)
        patch :send_offered_product_available_email, params: {locale: I18n.locale, id: product.id}
      end
    end
  end

  describe "PATCH /update_state" do
    let(:product) { create(:product, state: :canceled) }

    before { patch :update_state, params: {locale: I18n.locale, id: product.id, state: state} }

    context "when valid state" do
      let(:state) { "offered" }

      it { is_expected.to(redirect_to(admin_product_path)) }
      it { is_expected.to(set_flash[:notice]) }

      it "changes product state" do
        expect(product.reload.state).to eq state
      end
    end

    context "when invalid state" do
      let(:state) { "invalid_state" }

      it { is_expected.to(redirect_to(admin_product_path)) }
      it { is_expected.to(set_flash[:alert]) }

      it "doesn't change product state" do
        expect(product.reload.state).not_to eq state
      end
    end
  end

  describe "PATCH /customer_canceled" do
    let(:product) { create(:product, :sold_by_us, state: initial_state) }
    let(:cancellation_reason) { "just nope" }

    before do
      patch :customer_canceled, params: {
        locale: I18n.locale,
        id: product.id,
        product: {cancellation_reason: cancellation_reason}
      }
    end

    context "when transition impossible" do
      let(:initial_state) { "ordered" }

      it "sets alert and redirects to product page" do
        expect(response).to redirect_to(admin_product_path)
        expect(flash[:alert]).to be_present
      end

      it "does not change product state" do
        expect(product.reload.state).to eq initial_state
      end
    end

    context "when transition possible" do
      let(:initial_state) { "under_management" }

      it "sets notice and redirects to product page" do
        expect(response).to redirect_to(admin_product_path)
        expect(flash[:notice]).to be_present
      end

      it "changes product state to terminated" do
        expect(product.reload.state).to eq "canceled_by_customer"
      end

      it "saves cancellation reason" do
        expect(product.reload.cancellation_reason).to eq cancellation_reason
      end
    end
  end

  describe "PATCH /terminate" do
    let(:product) { create(:product, state: initial_state) }
    let(:cancellation_reason) { "just nope" }

    before do
      patch :terminate, params: {
        locale: I18n.locale,
        id: product.id,
        product: {cancellation_reason: cancellation_reason}
      }
    end

    context "when transition impossible" do
      let(:initial_state) { "ordered" }

      it "sets alert and redirects to product page" do
        expect(response).to redirect_to(admin_product_path)
        expect(flash[:alert]).to be_present
      end

      it "does not change product state" do
        expect(product.reload.state).to eq initial_state
      end
    end

    context "when transition possible" do
      let(:initial_state) { "details_available" }

      it "sets notice and redirects to product page" do
        expect(response).to redirect_to(admin_product_path)
        expect(flash[:notice]).to be_present
      end

      it "changes product state to terminated" do
        expect(product.reload.state).to eq "terminated"
      end

      it "saves cancellation reason" do
        expect(product.reload.cancellation_reason).to eq cancellation_reason
      end
    end
  end

  describe "GET new" do
    context "with attached retirement documents" do
      let(:document_ids) { %w[10 11] }
      let(:mandate_id) { create(:mandate).id.to_s }

      it "should query attached documents and assign to a instance variable" do
        expect(Document).to receive(:where).with(id: document_ids, documentable_id: mandate_id)
                                           .and_return([])
        get :new, params: {locale:                I18n.locale,
                           mandate_id:            mandate_id,
                           attached_document_ids: document_ids}
        expect(assigns(:attached_retirement_documents)).to eq([])
      end
    end
  end

  describe "POST create" do
    let(:mandate) { create(:mandate) }

    context "without attached retirement documents" do
      let(:product) do
        plan = create(:plan, :equity)
        FactoryBot.attributes_for(:product, :retirement_equity_category, plan_id: plan.id)
      end

      it "should not call .assign_retirement_documents_to_products" do
        expect(Domain::Retirement::RetirementProcess).not_to \
          receive(:assign_retirement_documents_to_products)
        post :create, params: {locale: I18n.locale, mandate_id: mandate.id, product: product}
      end

      it "creates a business_event with created admin" do
        allow(BusinessEvent).to receive(:audit).and_call_original.at_least(:once)
        post :create, params: {
          locale: I18n.locale, mandate_id: mandate.id, product: product
        }

        product = mandate.products.take
        expect(product.business_events.exists?(person: admin)).to be_truthy
      end
    end

    context "with attached retirement documents" do
      let(:document) { create(:document, :retirement_document, documentable: mandate) }
      let(:product) do
        plan = create(:plan, :equity)
        attrs = FactoryBot.attributes_for(:product, :retirement_equity_category, plan_id: plan.id)
        attrs.merge(attached_document_ids: [document.id])
      end

      it "should assign retirement documents to the product" do
        expect(Domain::Retirement::RetirementProcess).to receive(:assign_retirement_documents_to_products)
        post :create, params: {locale: I18n.locale, mandate_id: mandate.id, product: product}
      end

      it "should keep the state after server-side validation" do
        invalid_params = product.merge(portfolio_commission_price: "not number")
        post :create, params: {locale: I18n.locale, mandate_id: mandate.id, product: invalid_params}
        expect(response).to render_template(:new)
        expect(assigns(:attached_retirement_documents)).to eq([document])
      end
    end

    context "with multiple documents attached" do
      let(:plan) { create(:plan) }
      let(:document) do
        Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "assets", "mandate.pdf"))
      end

      let(:product) do
        attributes_for(:product, :retirement_equity_category, plan_id: plan.id).merge(
          documents_attributes: {
            "0" => {
              "asset" => [
                document,
                document
              ],
              "document_type_id" => DocumentType.deckungsnote.id
            },
            "1" => {
              "asset" => [
                document
              ],
              "document_type_id" => DocumentType.greeting.id
            }
          }
        )
      end

      it "assigns documents to product" do
        expect {
          post :create, params: { locale: I18n.locale, mandate_id: mandate.id, product: product }
        }.to change { Product.count }.by(1)

        expect(Product.last.documents.count).to eq 3
      end
    end
  end

  describe "POST bulk_upload" do
    context "without csv file" do
      it "responds with an alert" do
        post :bulk_upload, params: {locale: I18n.locale}
        expect(response).to redirect_to admin_root_path
        expect(flash[:alert]).not_to be_blank
      end
    end

    pending
  end

  describe "GET exists" do
    context "when there is a contract with the same number" do
      let(:product) { create(:product) }

      it "returns true" do
        get :exists, params: { locale: I18n.locale, number: product.number }

        expect(response.body).to eq("true")
      end
    end

    context "when there is a shared contract with the same number" do
      let(:product) { create(:product, :shared_contract) }

      it "returns false" do
        get :exists, params: { locale: I18n.locale, number: product.number }

        expect(response.body).to eq("false")
      end
    end

    context "product_number" do
      let(:expected) do
        {
          locale: "de",
          format: :json,
          action: "exists",
          controller: "admin/products",
          number: product_number
        }
      end

      shared_examples "match the correctly route" do
        it do
          expect(
            get: "/de/admin/products/exists?number=#{product_number}"
          ).to route_to(expected)
        end
      end

      context "when it has dots" do
        let(:product_number) { "661-PK-010.060.045.368" }

        it_behaves_like "match the correctly route"
      end

      context "when it has slashes" do
        let(:product_number) { "561/563071-D" }

        it_behaves_like "match the correctly route"
      end
    end
  end

  describe "PATCH order" do
    before do
      allow(Features).to receive(:active?).with(Features::ORDER_AUTOMATION).and_return(true)
      allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(false)
    end

    context "when products has both adivsory and cover note documents" do
      let(:product) { create(:product, :order_pending, :with_advisory_documentation, :with_cover_note) }

      before do
        subcompany = product.subcompany
        subcompany.update(contact_type: :direct_agreement, order_email: "email@example.org")
      end

      it "sends cover note" do
        expect(controller).to receive(:send_cover_note)

        patch :order, params: { locale: I18n.locale, id: product.id }
      end

      it "changes product states" do
        patch :order, params: { locale: I18n.locale, id: product.id }

        product.reload
        expect(product.state).to eq("ordered")
      end
    end

    shared_examples "a failure" do
      let(:email) { "email@example.org" }
      let(:contact_type) { :direct_agreement }

      before do
        subcompany = product.subcompany
        subcompany.update(contact_type: contact_type, order_email: email)

        patch :order, params: { locale: I18n.locale, id: product.id }
        product.reload
      end

      it "does not changes product states" do
        expect(product.state).not_to eq("ordered")
      end

      it "returns correct flash message" do
        expect(flash[:alert]).to eq(message)
      end
    end

    context "when cover note is missing" do
      let(:product) { create(:product, :order_pending, :with_advisory_documentation) }
      let(:message) { 'Das Produkt kann nur auf "bestellt" gesetzt werden, wenn die Dokumente vorbereitet wurden' }

      it_behaves_like "a failure"
    end

    context "when advisory documentation is missing" do
      let(:product) { create(:product, :order_pending, :with_cover_note) }
      let(:message) { 'Das Produkt kann nur auf "bestellt" gesetzt werden, wenn eine Beratungsdokumentation angehangen wurde' }

      it_behaves_like "a failure"
    end

    context "when contact type is not defined" do
      let(:product) { create(:product, :order_pending, :with_advisory_documentation, :with_cover_note) }
      let(:message) { 'Das Produkt kann nur auf "bestellt" gesetzt werden, wenn eine Bestellung-E-Mail hinterlegt wurde.' }

      it_behaves_like "a failure" do
        let(:contact_type) { :undefined }
      end
    end
  end
end
