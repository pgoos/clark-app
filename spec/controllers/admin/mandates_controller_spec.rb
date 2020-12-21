# frozen_string_literal: true

require "rails_helper"

def cell_selector(row, column)
  "table tbody tr:nth-of-type(#{row}) td:nth-of-type(#{column})"
end

RSpec.describe Admin::MandatesController, :integration, type: :controller do
  let(:mandate) { create(:mandate, state: :accepted, first_name: "John") }
  let(:role)    { create(:role, permissions: Permission.where(controller: "admin/mandates")) }
  let(:admin)   { create(:admin, role: role) }

  before { login_admin(admin) }

  after { Settings.reload! }

  describe "GET index" do
    render_views

    let!(:mandate1) { create :mandate }
    let!(:mandate2) { create :mandate }

    it "responds with success" do
      get :index, params: {format: :html, locale: :de}

      expect(response).to have_http_status(:ok)
    end

    context "when ewe_datum visibility setting is true" do
      before { allow(Settings).to receive_message_chain("admin.mandate.index.ewe_datum").and_return(true) }

      it "renders ewe_datum column" do
        document = create :document, :mandate_document_biometric, documentable: mandate1
        create :document, :cover_note, documentable: mandate2

        get :index, params: {format: :html, locale: :de}

        expect(response.body).to match(I18n.t("activerecord.attributes.documents.created_at"))
        expect(response.body).to have_selector(cell_selector(1, 1), text: mandate2.id)
        expect(response.body).to have_selector(cell_selector(2, 1), text: mandate1.id)
        expect(response.body).to have_selector(cell_selector(1, 7), text: "")
        expect(response.body).to have_selector(cell_selector(2, 7), text: document.created_at.strftime("%d.%m.%Y"))
      end

      it "renders mandate sorted by ewe-datum asc" do
        document1 = create :document, :mandate_document_biometric, documentable: mandate1, created_at: 10.days.ago
        document2 = create :document, :mandate_document_biometric, documentable: mandate2, created_at: 11.days.ago

        get :index, params: {order: "documents.created_at_asc", format: :html, locale: :de}

        expect(response.body).to have_selector(cell_selector(1, 7), text: document2.created_at.strftime("%d.%m.%Y"))
        expect(response.body).to have_selector(cell_selector(2, 7), text: document1.created_at.strftime("%d.%m.%Y"))
      end

      it "renders mandate sorted by ewe-datum desc" do
        document1 = create :document, :mandate_document_biometric, documentable: mandate1, created_at: 10.days.ago
        document2 = create :document, :mandate_document_biometric, documentable: mandate2, created_at: 11.days.ago

        get :index, params: {order: "documents.created_at_desc", format: :html, locale: :de}

        expect(response.body).to have_selector(cell_selector(1, 7), text: document1.created_at.strftime("%d.%m.%Y"))
        expect(response.body).to have_selector(cell_selector(2, 7), text: document2.created_at.strftime("%d.%m.%Y"))
      end
    end

    context "when ewe_datum visibility setting is false" do
      before { allow(Settings).to receive_message_chain("admin.mandate.index.ewe_datum").and_return(false) }

      it "does not render ewe_datum column" do
        document = create :document,
                          :mandate_document_biometric,
                          documentable: create(:mandate),
                          created_at: 10.days.ago

        get :index, params: {format: :html, locale: :de}

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to match(I18n.t("activerecord.attributes.documents.created_at"))
        expect(response.body).not_to match(document.created_at.strftime("%d.%m.%Y"))
      end
    end
  end

  describe "AccessLog" do
    let(:log_prefix_pattern) { /ACCESS_LOG/ }
    let(:call) { get :index, params: {locale: :de} }

    before do
      allow(Rails.logger).to receive(:info).and_call_original
      allow(Settings).to receive_message_chain("security.access_log")
        .and_return(access_log_enabled)
    end

    context "when enabled" do
      let(:access_log_enabled) { true }

      it "saves a log entry" do
        expect(Rails.logger).to receive(:info)
          .with(log_prefix_pattern).at_least(:once)
        call
      end
    end

    context "when disabled" do
      let(:access_log_enabled) { false }

      it "doesn't save a log entry" do
        expect(Rails.logger).not_to receive(:info).with(log_prefix_pattern)
        call
      end
    end
  end

  describe "GET /new" do
    it { is_expected.to use_before_action(:can_manage_mandate?) }

    context "when Feature Switch is on" do
      before do
        allow(Features).to receive(:active?).with(Features::OPSUI_MANDATE_CREATION).and_return(true)

        get :new, params: {locale: :de}
      end

      it { is_expected.to render_template("new") }
    end

    context "when Feature Switch is off" do
      before do
        allow(Features).to receive(:active?).with(Features::OPSUI_MANDATE_CREATION).and_return(false)

        get :new, params: {locale: :de}
      end

      it { is_expected.to redirect_to(admin_mandates_path) }
    end
  end

  describe "POST /create" do
    let(:domain) { n_double("domain") }
    let(:params) do
      {first_name: "Foo", last_name: "Bar", birthdate: "01/01/1990", gender: "male", street: "Goethestr.",
       house_number: "10", zipcode: "60313", city: "Frankfurt", phone: "1234567890", country_code: "DE",
       transfer_data_to_bank: "true", reference_id: "1",
       user: {email: "test@clark.de", password: "Test1234", password_confirmation: "Test1234"}, document: {asset: ""}}
    end

    before do
      allow(Domain::MandateOfflineCreation).to receive(:new).with(params).and_return(domain)
      allow(domain).to receive(:without_confirmation).and_return(mandate)
    end

    it "permits mandates' params" do
      expect(subject).to permit(:first_name, :last_name, :birthdate, :gender, :street, :house_number,
                                :zipcode, :city, :phone, :country_code, :transfer_data_to_bank,
                                :reference_id, user: %i[email password password_confirmation],
                                               document: [:asset])
        .for(:create, params: {locale: :de, mandate: params})
        .on(:mandate)
    end

    context "with valid attributes" do
      let(:mandate) { build_stubbed(:mandate, state: :accepted) }

      before { post :create, params: {locale: :de, mandate: params} }

      it { expect(domain).to have_received(:without_confirmation) }
      it { is_expected.to set_flash[:notice] }
      it { is_expected.to redirect_to(admin_mandates_path) }
    end

    context "with invalid attributes" do
      let(:mandate) { double("Mandate").as_null_object }

      before do
        allow(mandate).to receive(:valid?).and_return(false)
        post :create, params: {locale: :de, mandate: params}
      end

      it { expect(domain).to have_received(:without_confirmation) }
      it { is_expected.to render_template("new") }
    end
  end

  describe "PATCH #revoke" do
    before do
      patch :revoke, params: {format: :html, locale: I18n.locale, id: mandate.id}
    end

    context "when customer revocation has been failed" do
      let(:mandate) { create(:mandate, state: :revoked) }

      it { is_expected.to set_flash }
      it { expect(flash[:alert]).to eq(I18n.t("flash.actions.revoke.error")) }
      it { is_expected.to render_template("show") }
    end

    context "when customer revocation is successful" do
      before do
        allow_any_instance_of(Domain::RevokeCustomers::RevokeCustomerProcess).to \
          receive(:send_revokation_email)
      end

      it { is_expected.to set_flash }
      it { expect(flash[:notice]).to eq(I18n.t("flash.alert.mandate_revoked")) }
      it { is_expected.to redirect_to admin_mandate_path(mandate) }

      it "should change mandate state to revoked" do
        expect(mandate.reload.state).to eq("revoked")
      end
    end
  end

  describe "PATCH #request_corrections" do
    before do
      allow(Domain::AcceptCustomers::Processes).to receive(:request_corrections_process)
    end

    context "with clark1 customer" do
      let(:mandate) { create(:mandate, :created) }

      before do
        patch :request_corrections, params: { format: :html, locale: I18n.locale, id: mandate.id }
      end

      it do
        expect(Domain::AcceptCustomers::Processes).to \
          have_received(:request_corrections_process).with(mandate)
      end
    end

    context "with clark2 customer" do
      let(:mandate) { create(:mandate, :created, customer_state: :mandate_customer) }
      let(:mail) { double :mail, deliver_later: nil }
      let(:messenger) { double :messenger, send_message: nil }

      before do
        allow(Features).to receive(:active?).and_return true
        allow(MandateMailer).to receive(:request_corrections).with(mandate).and_return mail
        allow(OutboundChannels::Messenger::MessageDelivery).to \
          receive(:new).with(
            kind_of(String),
            mandate,
            kind_of(Admin),
            identifier: "messenger.upgrade_corrections_requested"
          ).and_return(messenger)
      end

      it "updates states and notifies customer" do
        expect(mail).to receive(:deliver_later)
        expect(messenger).to receive(:send_message)

        perform_enqueued_jobs do
          patch :request_corrections,
                params: { format: :html, locale: I18n.locale, id: mandate.id }
        end

        mandate.reload
        expect(mandate.state).to eq "in_creation"
        expect(mandate.customer_state).to eq "self_service"
        expect(mandate.wizard_steps).to eq []
      end
    end
  end

  describe "POST #create_arisecur_customer" do
    before do
      allow(Carrier).to receive(:create_customer).with(mandate.id).and_return(result)
      post :create_arisecur_customer, params: { format: :html, locale: I18n.locale, id: mandate.id }
    end

    context "when service returns success" do
      let(:result) { instance_double(Utils::Interactor::Result, success?: true) }

      it { is_expected.to set_flash }
      it { expect(flash[:notice]).to eq(I18n.t("flash.actions.create_arisecur_customer.notice")) }
      it { is_expected.to redirect_to admin_mandate_path(mandate) }
    end

    context "when service returns failure" do
      let(:result) { instance_double(Utils::Interactor::Result, success?: false, errors: ["Problem with API!"]) }

      it { is_expected.to render_template("show") }
    end
  end

  describe "#can_be_invited?" do
    let(:controller_instance) { described_class.new }
    let(:external_mandate) { instance_double("Mandate") }
    let(:source_campaign) { "source campaign" }
    let(:network) { "network" }
    let(:owner_ident) { "owner_ident" }

    before do
      allow(external_mandate).to receive(:in_creation?).and_return(true)
      allow(external_mandate).to receive(:source_campaign).and_return(source_campaign)
      allow(external_mandate).to receive(:network).and_return(network)
      allow(external_mandate).to receive(:owner_ident).and_return(owner_ident)
      allow(Settings).to receive_message_chain(:admin, :mandate, :invite, :campaign).and_return([])
      allow(Settings).to receive_message_chain(:admin, :mandate, :invite, :network).and_return([])
      allow(Settings).to receive_message_chain(:admin, :mandate, :invite, :active).and_return(true)
    end

    it "returns false if context is not clark" do
      allow(Settings).to receive_message_chain(:admin, :mandate, :invite, :active).and_return(false)
      expect(controller_instance.send(:can_be_invited?, external_mandate)).to be_falsey
    end

    it "returns false if mandate is not in creation" do
      allow(external_mandate).to receive(:in_creation?).and_return(false)
      expect(controller_instance.send(:can_be_invited?, external_mandate)).to be_falsey
    end

    it "returns true if mandate campaign is in the allowed campaigns" do
      allow(Settings).to receive_message_chain(:admin, :mandate, :invite, :campaign).and_return([source_campaign])
      expect(controller_instance.send(:can_be_invited?, external_mandate)).to be_truthy
    end

    it "returns true if mandate network is in the allowed networks" do
      allow(Settings).to receive_message_chain(:admin, :mandate, :invite, :network).and_return([network])
      expect(controller_instance.send(:can_be_invited?, external_mandate)).to be_truthy
    end

    context "mandate owner is in the allowed owner idents" do
      let!(:partner) { create(:partner, :active, ident: owner_ident) }

      it "return true" do
        expect(controller_instance.send(:can_be_invited?, external_mandate)).to be_truthy
      end
    end
  end

  describe "POST /export" do
    before do
      allow(Settings.ops_ui.mandate).to receive(:export_enabled).and_return(true)
    end

    it "queues export job for given mandate" do
      expect(Domain::DataProtection::CustomerExport).to(
        receive(:call).and_call_original
      )
      post :export, params: {id: mandate.id, locale: I18n.locale}
      expect(request.flash["notice"]).to eq I18n.t("admin.mandates.export.started")
      expect(response.status).to eq 302
    end

    it "returns message if export already started" do
      mandate.info["status_data_protection"] = "started!"
      mandate.save
      post :export, params: {id: mandate.id, locale: I18n.locale}
      expect(request.flash["notice"]).to eq I18n.t("admin.mandates.export.in_progress")
      expect(response.status).to eq 302
    end
  end

  describe "POST /delete" do
    before do
      allow(Settings.ops_ui.mandate).to receive(:delete_enabled).and_return(true)
    end

    it "queues delete all job for given mandate" do
      expect(Domain::DataProtection::CustomerDelete).to(
        receive(:call).and_call_original
      )
      post :delete, params: {id: mandate.id, locale: I18n.locale}
      expect(request.flash["notice"]).to eq I18n.t("admin.mandates.delete.started")
      expect(response.status).to eq 302
    end

    it "returns message if delete already started" do
      mandate.info["status_data_protection"] = "started!"
      mandate.save
      post :delete, params: {id: mandate.id, locale: I18n.locale}
      expect(request.flash["notice"]).to eq I18n.t("admin.mandates.delete.in_progress")
      expect(response.status).to eq 302
    end
  end

  describe "GET /show" do
    render_views

    let(:content) { "some interaction content." }
    let(:consultant) { create(:admin, first_name: Faker::Name.first_name, last_name: Faker::Name.first_name) }

    context "Interaction::Message" do
      context "mandate has an interaction from an admin" do
        it "shows interaction with admin name" do
          create(:interaction_message,
                 mandate: mandate,
                 admin: consultant,
                 content: content,
                 direction: "out")

          get :show, params: {id: mandate.id, locale: I18n.locale}

          expect(response.status).to  eq 200
          expect(response.body).to    match(Regexp.new(content))
          expect(response.body).to    match(Regexp.new(consultant.name))
          expect(response.body).to    include('{"data":{"mandate":{"first_name": "John"}}}')
        end
      end

      context "mandate has an interaction without admin" do
        it "shows interaction with proxy admin name" do
          create(:interaction_message,
                 mandate: mandate,
                 admin: nil,
                 content: content,
                 direction: "out")

          get :show, params: {id: mandate.id, locale: I18n.locale}

          expect(response.status).to  eq 200
          expect(response.body).to    match(Regexp.new(content))
          expect(response.body).to    match(Regexp.new(I18n.t("admin.interactions.proxy_name")))
        end
      end
    end

    context "Interaction::Email" do
      context "mandate has an interaction from an admin" do
        it "shows interaction with admin name" do
          create(:interaction_email,
                 mandate: mandate,
                 admin: consultant,
                 content: content,
                 direction: "out")

          get :show, params: {id: mandate.id, locale: I18n.locale}

          expect(response.status).to  eq 200
          expect(response.body).to    match(Regexp.new(content))
          expect(response.body).to    match(Regexp.new(consultant.name))
        end
      end

      context "mandate has an interaction without admin" do
        it "shows interaction with proxy admin name" do
          create(:interaction_email,
                 mandate: mandate,
                 admin: nil,
                 content: content,
                 direction: "out")

          get :show, params: {id: mandate.id, locale: I18n.locale}

          expect(response.status).to  eq 200
          expect(response.body).to    match(Regexp.new(content))
          expect(response.body).to    match(Regexp.new(I18n.t("admin.interactions.proxy_name")))
        end
      end
    end
  end
end
