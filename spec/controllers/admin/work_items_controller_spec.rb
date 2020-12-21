# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::WorkItemsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/work_items")) }
  let(:admin) { create(:admin, role: role) }
  let(:mandate) { create(:mandate) }

  before { sign_in(admin) }

  describe "GET /show -> root" do
    context "when logged in" do
      context "when json request" do
        before { get :show, format: :json, params: { locale: I18n.locale } }

        it { expect(response).to be_ok }
      end

      context "when root path" do
        before do
          request.env["PATH_INFO"] = "/de/admin"

          get :show, params: { locale: I18n.locale }
        end

        it { expect(response).to be_ok }
      end
    end

    context "when not logged" do
      before do
        sign_out(admin)

        get :show, params: { locale: I18n.locale }
      end

      it { expect(response).not_to be_ok }
    end
  end

  describe "#accepted_offers" do
    subject { get :accepted_offers, params: { locale: :de } }

    let!(:product)      { create :product, state: :order_pending }
    let!(:offer)        { create :offer, state: :accepted }
    let!(:offer_option) { create :offer_option, offer: offer, product: product }

    context 'when offer in state "accepted" or "active" with product in state "order_pending" exists' do
      it "loads the list of accepted offers work items" do
        subject
        expect(response.status).to eq(200)
        expect(assigns(:accepted_offers)).to eq([offer])
      end

      it "loads active offers as well descending by updated date" do
        active_offer = create :offer, state: :active, active_offer_selected: true
        create :offer_option, offer: active_offer, product: product

        subject

        expect(response.status).to eq(200)
        expect(assigns(:accepted_offers)).to eq([active_offer, offer])
      end
    end

    context "when opportunity is lost" do
      it "does not render the offer" do
        opportunity = create :opportunity, state: :lost
        lost_offer = create :offer, state: :active, active_offer_selected: true, opportunity: opportunity
        create :offer_option, offer: lost_offer, product: product

        subject

        expect(assigns(:accepted_offers)).to eq([offer])
      end
    end

    context "when opportunity is completed" do
      it "does not render the offer" do
        opportunity = create :opportunity, state: :completed
        completed_offer = create :offer, state: :active, active_offer_selected: true, opportunity: opportunity
        create :offer_option, offer: completed_offer, product: product

        subject

        expect(assigns(:accepted_offers)).to eq([offer])
      end

      context "when category is GKV" do
        it "does not render the offer" do
          category = create :category, ident: "3659e48a" # GKV
          opportunity = create :opportunity, state: :completed, category: category
          completed_offer = create :offer, state: :accepted, active_offer_selected: true, opportunity: opportunity
          create :offer_option, offer: completed_offer, product: product

          subject

          expect(assigns(:accepted_offers)).to eq([completed_offer, offer])
        end

        context "when old product is cancelled" do
          it "does not render the offer" do
            category = create :category, ident: "3659e48a" # GKV
            old_product = create :product, state: :canceled
            opportunity = create :opportunity, state: :completed, category: category, old_product: old_product
            completed_offer = create :offer, state: :accepted, active_offer_selected: true, opportunity: opportunity
            create :offer_option, offer: completed_offer, product: product

            subject

            expect(assigns(:accepted_offers)).to eq([offer])
          end
        end
      end
    end
  end

  describe "#incoming_messages" do
    let(:mandate) { create(:mandate) }
    let!(:message1) { create(:incoming_message, :unread, mandate: mandate, admin_id: admin.id) }
    let!(:message2) { create(:incoming_message, :read, mandate: mandate, admin_id: nil) }

    context "without filter params" do
      it "return mandates with incoming unread messages from the last 30 days" do
        get :incoming_messages, params: { locale: :de }

        expect(response.status).to eq(200)
        expect(assigns(:mandate_ids)).to eq([mandate.id])
        expect(assigns(:mandates).first.interactions.map(&:id)).to eq([message1.id])
      end
    end

    context "with by_acknowledged filter params" do
      it "return mandates with incoming messages with that specific acknowledged state" do
        get :incoming_messages, params: { locale: :de, by_acknowledged: "true" }

        expect(response.status).to eq(200)
        expect(assigns(:mandate_ids)).to eq([mandate.id])
        expect(assigns(:mandates).first.interactions.map(&:id)).to eq([message2.id])
      end
    end

    context "with by_admin_id filter params" do
      it "return mandates with incoming messages that assigns to that specific admiin" do
        get :incoming_messages, params: { locale: :de, by_admin_id: admin.id }

        expect(response.status).to eq(200)
        expect(assigns(:mandate_ids)).to eq([mandate.id])
        expect(assigns(:mandates).first.interactions.map(&:id)).to eq([message1.id])
      end
    end

    context "with by_current_admin filter params" do
      it "return mandates with incoming messages that current admin assign with" do
        get :incoming_messages, params: { locale: :de, by_current_admin: "true" }

        expect(response.status).to eq(200)
        expect(assigns(:mandate_ids)).to eq([mandate.id])
        expect(assigns(:mandates).first.interactions.map(&:id)).to eq([message1.id])
      end
    end
  end

  describe "#refresh_unanswered_interactions_count" do
    subject { get :refresh_unanswered_interactions_count, params: { locale: :de, format: :json } }

    before do
      Rails.cache.clear("fetch_unanswered_messages_count")
    end

    let(:mandate) { create(:mandate) }
    let(:admin)   { create(:admin) }
    let(:content) { Faker::Lorem.characters(number: 50) }

    it "gets all incoming un-aknowledged interactions count" do
      # unread_message
      Interaction::Message.create!(
        content:   content,
        mandate:   mandate,
        admin:     admin,
        direction: Interaction.directions[:in]
      )

      # read_message
      Interaction::Message.create!(
        content:      content,
        mandate:      mandate,
        admin:        admin,
        direction:    Interaction.directions[:in],
        acknowledged: true
      )

      subject

      # this action should not be considered "user activity" by Devise, so we `skip_trackable`
      expect(request.env["devise.skip_trackable"]).to eq(true)
      expect(response.status).to eq(200)
      expect(json_response["unanswerd_count"]).to eq(1)
    end

    it "does not includes advice replies as well" do
      create(:interaction_sms, mandate:      mandate,
                                           admin:        admin,
                                           direction:    Interaction.directions[:in],
                                           acknowledged: false,
                                           topic:        mandate)

      subject

      expect(json_response["unanswerd_count"]).to eq(0)
    end
  end

  describe "#contacted_inquiries", :business_events do
    let(:inquiry) { create(:inquiry) }

    before do
      inquiry.accept!
      inquiry.contact!
    end

    it "returns contacted inquiries" do
      get :contacted_inquiries, params: { locale: :de }
      expect(response.status).to eq(200)
      expect(assigns(:contacted_inquiries)).to eq([inquiry])
    end

    context "when rendering view" do
      render_views

      before do
        inquiry.business_events.find_by(action: "accept").destroy
        get :contacted_inquiries, params: { locale: :de, format: :html }
      end

      it "renders the view" do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe "#retirement_documents" do
    context "without retirement documents" do
      it "assigns documents_with_mandates as empty" do
        get :retirement_documents, params: { locale: :de }
        expect(response.status).to eq(200)
        expect(assigns(:documents_with_mandates)).to eq([])
      end
    end

    context "with retirement documents" do
      let!(:mandate) { create(:mandate) }
      let!(:retirement_document) do
        create(:document, :retirement_document, documentable: mandate)
      end

      it "assigns documents_with_mandates as with mandate" do
        get :retirement_documents, params: { locale: :de }
        expect(response.status).to eq(200)
        expect(assigns(:documents_with_mandates)).to match_array([mandate])
      end
    end

    context "with pagination" do
      let!(:entities) do
        Array.new(3).map do
          mandate = create(:mandate)
          create(:document, :retirement_document, documentable: mandate)
          mandate
        end
      end

      it_behaves_like "paginated entities", :retirement_documents, :documents_with_mandates
    end
  end

  describe "#my_follow_ups" do
    context "with pagination" do
      let!(:entities) do
        Array.new(3).map do
          create(:follow_up, admin: admin, item: mandate)
        end
      end

      it_behaves_like "paginated entities", :my_follow_ups, :my_follow_ups
    end

    context "without any filter param" do
      let!(:follow_up1) { create(:follow_up, :unacknowledged, admin: admin, item: mandate) }
      let!(:follow_up2) { create(:follow_up, :unacknowledged, item: mandate) }
      let!(:follow_up3) { create(:follow_up, :acknowledged, item: mandate) }

      it "should only returns unacknowledged follow_ups that belongs to the admin" do
        get :my_follow_ups, params: { locale: :de }
        expect(assigns(:my_follow_ups).map(&:id)).to eq([follow_up1.id])
      end
    end

    context "with by_interaction_type filter param" do
      let!(:follow_up1) do
        create(:follow_up, :unacknowledged, :phone_call, admin: admin, item: mandate)
      end
      let!(:follow_up2) do
        create(:follow_up, :unacknowledged, :message, admin: admin, item: mandate)
      end

      it "should only returns unacknowledged follow_ups according to the interaction_type" do
        get :my_follow_ups, params: { locale: :de, by_interaction_type: "phone_call" }
        expect(assigns(:my_follow_ups).map(&:id)).to eq([follow_up1.id])
      end
    end
  end

  describe "#my_opportunities" do
    context "with pagination" do
      let!(:entities) do
        Array.new(3).map do
          create(:opportunity, admin: admin, state: "initiation_phase")
        end
      end

      it_behaves_like "paginated entities", :my_opportunities, :my_opportunities
    end
  end

  describe "GET pending_ocr_recognitions" do
    context "with pagination" do
      let!(:entities) do
        [
          create(:ocr_recognition, :with_product_validation_succeded),
          create(:ocr_recognition, :with_product_validation_failed)
        ]
      end

      it_behaves_like "paginated entities", :pending_ocr_recognitions, :pending_ocr_recognitions
    end
  end

  describe "GET incoming_messages" do
    let(:vertical) { create(:vertical) }
    let(:mandate) { create(:mandate) }
    let(:subcompany) { create(:subcompany, verticals: [vertical]) }
    let(:plan) { create(:plan, category: category, vertical: vertical, subcompany: subcompany) }
    let(:category) { create(:category, vertical: vertical) }
    let(:product) { create(:product, mandate: mandate, plan: plan) }

    let!(:messages) do
      create_list(:interaction_message, 3, direction: "in", mandate: mandate, admin: admin)
    end

    it "fetch mandates with incoming_messages" do
      get :incoming_messages, params: { locale: :de }
      expect(response.status).to eq(200)

      expect(assigns(:mandate_ids).count).to eq(1)
      expect(assigns(:mandates).first.interactions.count).to eq(3)
    end
  end

  describe "#unassigned_opportunities" do
    context "with pagination" do
      let!(:entities) do
        Array.new(3).map do
          create(:opportunity, admin: nil)
        end
      end

      it_behaves_like "paginated entities", :unassigned_opportunities, :unassigned_opportunities

      context "with query params", :integration do
        let(:low_margin_category) { create(:category, :low_margin) }
        let(:medium_margin_category) { create(:category, :medium_margin) }
        let!(:entities) do
          [
            create(:opportunity, admin: nil, category: low_margin_category),
            create(:opportunity, admin: nil, category: medium_margin_category),
            create(:opportunity, admin: nil, category: medium_margin_category)
          ]
        end
        let!(:appointment) { create(:appointment, mandate: entities[1].mandate, appointable: entities[1]) }

        it "filters opportunities" do
          get :unassigned_opportunities, params: { locale: :de }
          expect(response.status).to eq(200)
          expect(assigns(:unassigned_opportunities).size).to eq 3

          get :unassigned_opportunities, params: { locale: :de, margin_level: "low" }
          expect(response.status).to eq(200)
          expect(assigns(:unassigned_opportunities).size).to eq 1

          get :unassigned_opportunities, params: { locale: :de, margin_level: "low", appointment_scheduled: "yes" }
          expect(response.status).to eq(200)
          expect(assigns(:unassigned_opportunities).size).to eq 0

          get :unassigned_opportunities, params: { locale: :de, margin_level: "medium", appointment_scheduled: "yes" }
          expect(response.status).to eq(200)
          expect(assigns(:unassigned_opportunities).size).to eq 1
        end
      end
    end
  end

  describe "#accepted_offers" do
    context "with pagination" do
      let!(:entities) do
        Array.new(3).map do
          create(
            :offer,
            state: "accepted",
            opportunity: create(:opportunity),
            offer_options: [
              create(
                :offer_option,
                product: create(:product, state: "termination_pending"),
                recommended: true
              )
            ]
          )
        end
      end

      it_behaves_like "paginated entities", :accepted_offers, :accepted_offers
    end
  end

  describe "#customer_uploaded_inquiry_category_documents" do
    let(:repository_double) { instance_double(Domain::Inquiries::InquiryCategoryRepository) }
    let!(:entities) do
      create_list(:inquiry_category, 2)
    end
    let(:dumb_relation) { InquiryCategory.all }

    before do
      allow(Domain::Inquiries::InquiryCategoryRepository).to receive(:new).and_return(repository_double)
      allow(repository_double).to receive(:with_older_active_customer_uploads).and_return(dumb_relation)
    end

    it "loads the correct inquiry_categories" do
      get :customer_uploaded_inquiry_category_documents, params: { locale: :de }
      expect(response).to have_http_status(:ok)
      assigned_inquiries = assigns(:inquiries)
      expect(assigned_inquiries.first.documents.loaded?).to eq true
      expect(assigned_inquiries.second.documents.loaded?).to eq true
      expect(repository_double).to have_received(:with_older_active_customer_uploads)
    end

    it "loads the newer inquiry_categories" do
      allow(repository_double).to receive(:with_newer_active_customer_uploads).and_return(dumb_relation)
      get :customer_uploaded_inquiry_category_documents, params: { locale: :de, order: :document_created_at_desc }
      expect(response).to have_http_status(:ok)
      assigned_inquiries = assigns(:inquiries)
      expect(assigned_inquiries.first.documents.loaded?).to eq true
      expect(repository_double).to have_received(:with_newer_active_customer_uploads)
    end

    it_behaves_like "paginated entities", :customer_uploaded_inquiry_category_documents, :inquiries
  end

  describe "#product_updates" do
    let(:product) { create(:product) }

    context "when valid document exists" do
      let!(:document) do
        create(
          :document,
          :customer_upload,
          documentable: product,
          created_at: Date.new(2019, 2, 1)
        )
      end

      before do
        get :product_updates, params: { locale: :de }
      end

      it { expect(response).to be_successful }
      it { is_expected.not_to render_with_layout }
      it { is_expected.to render_template("product_updates") }
      it { expect(assigns(:documents)).to eq [document] }
    end

    context "when revoked_mandate's document exists" do
      let(:active_mandate) { mandate }
      let(:revoked_mandate) { create(:mandate, :revoked) }
      let(:product_for_active_mandate) { create(:product, mandate: active_mandate) }
      let(:product_for_revoked_mandate) { create(:product, mandate: revoked_mandate) }
      let!(:document_for_active_mandate) do
        create(:document, :customer_upload, documentable: product_for_active_mandate)
      end
      let!(:document_for_revoked_mandate) do
        create(:document, :customer_upload, documentable: product_for_revoked_mandate)
      end

      context "when current_admin does not have permission to view revoked_mandate" do
        it "does not show document for revoked mandate" do
          get :product_updates, params: { locale: :de }

          expect(response).to be_successful
          expect(assigns(:documents)).to match([document_for_active_mandate])
        end
      end

      context "when current_admin does have permission to view revoked_mandate" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "show document for revoked mandate" do
          get :product_updates, params: { locale: :de }

          expect(response).to be_successful
          expect(assigns(:documents)).to match_array(
            [document_for_active_mandate, document_for_revoked_mandate]
          )
        end
      end
    end
  end

  context "when self service customer" do
    let(:product) { create(:product, mandate_id: customer.id, state: :order_pending) }
    let!(:document) { create(:document, :customer_upload, documentable: product) }
    let!(:opportunity) { create(:opportunity, admin: nil, mandate_id: customer.id, state: :created) }
    let!(:follow_up) { create(:follow_up, admin: admin, item: opportunity) }
    let!(:offer) { create :offer, state: :accepted }
    let!(:offer_option) { create :offer_option, offer: offer, product: product }

    %i[prospect self_service].each do |state|
      context "with #{state} state" do
        let(:customer) { create(:customer, state) }

        it "appears in work item views" do
          # unassigned_opportunities
          get :unassigned_opportunities, params: { locale: I18n.locale }
          expect(assigns(:unassigned_opportunities).map(&:id)).to include(opportunity.id)

          # my_opportunities
          opportunity.update admin_id: admin.id, state: :initiation_phase
          get :my_opportunities, params: { locale: I18n.locale }
          expect(assigns(:my_opportunities).map(&:id)).to include(opportunity.id)

          # my_follow_ups
          get :my_follow_ups, params: { locale: I18n.locale }
          expect(assigns(:my_follow_ups).map(&:id)).to include(follow_up.id)

          # accepted_offers
          get :accepted_offers, params: { locale: I18n.locale }
          expect(assigns(:accepted_offers).map(&:id)).to include(offer.id)

          # track_special_customers
          Mandate.find(customer.id).update variety: :vip
          get :track_special_customers, params: { locale: I18n.locale }
          expect(assigns(:special_customers).map(&:id)).to include(customer.id)
        end
      end
    end
  end

  describe "#customer_uploaded_contract_documents" do
    let!(:contracts) { create_list(:contract, 1, :under_analysis) }

    before do
      allow(Settings).to receive_message_chain(:app_features, :clark2) { true }
      get :customer_uploaded_contract_documents, params: { locale: :de }
    end

    it { expect(response).to be_successful }
    it { is_expected.not_to render_with_layout }
    it { is_expected.to render_template("customer_uploaded_contract_documents") }

    it "returns valid data" do
      expect(assigns(:contracts).size).to eq contracts.size
      expect(assigns(:contracts).map(&:id)).to eq contracts.map(&:id)
    end
  end

  describe ".track_special_customers" do
    context "with normal mandate" do
      let!(:mandate) { create(:mandate, variety: nil) }

      it "should not include normal customer" do
        get :track_special_customers, params: { locale: I18n.locale }
        expect(assigns(:special_customers)).to be_empty
      end
    end

    context "with special customer" do
      let!(:mandate) { create(:mandate, :vip) }

      it "should include special customer in the result" do
        get :track_special_customers, params: { locale: I18n.locale }
        expect(assigns(:special_customers).map(&:id)).to eq([mandate.id])
      end

      context 'with revoked special mandate documents' do
        let!(:revoked_mandate) { create(:mandate, :revoked, :vip) }

        it "should only include active special customer in the result" do
          get :track_special_customers, params: { locale: I18n.locale }
          expect(assigns(:special_customers).map(&:id)).to eq([mandate.id])
        end

        context "admin with can_view_revoked_mandates? permission" do
          before do
            admin.permissions << create(:permission, :view_revoked_mandates)
          end

          it "include all special customers in the result" do
            get :track_special_customers, params: { locale: I18n.locale }
            expect(assigns(:special_customers).map(&:id)).to match_array([mandate.id, revoked_mandate.id])
          end
        end
      end
    end
  end
end
