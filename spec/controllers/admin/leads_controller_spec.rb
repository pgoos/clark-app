# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::LeadsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/leads")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

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
  #
  #
  #
  #

  # TODO: REMOVE!
  it "makes the tests work since for some weird reason the first test is not logged in" do
    expect(1).to be(1)
  end

  context "#confirm" do
    let!(:lead) { create(:lead, confirmed_at: nil, mandate: create(:mandate)) }

    it "manually sets the confirmed_at flag for the lead" do
      patch :confirm, params: {id: lead, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(lead.mandate))

      lead.reload
      expect(lead).to be_confirmed
    end
  end

  context "#unconfirm" do
    let!(:lead) { create(:lead, confirmed_at: DateTime.now, mandate: create(:mandate)) }

    it "manually removes the confirmation" do
      patch :unconfirm, params: {id: lead, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(lead.mandate))

      lead.reload
      expect(lead).not_to be_confirmed
    end
  end

  context "#subscribe" do
    let!(:lead) { create(:lead, confirmed_at: DateTime.now, subscriber: false, mandate: create(:mandate)) }

    it "manually subscribes the lead" do
      patch :subscribe, params: {id: lead, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(lead.mandate))

      lead.reload
      expect(lead.subscriber).to be_truthy
    end
  end

  context "#unsubscribe" do
    let!(:lead) { create(:lead, confirmed_at: DateTime.now, subscriber: true, mandate: create(:mandate)) }

    it "manually un-subscribes the lead" do
      patch :unsubscribe, params: {id: lead, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(lead.mandate))

      lead.reload
      expect(lead.subscriber).to be_falsey
    end
  end

  describe "POST /convert" do
    let(:lead)    { create(:lead, mandate: create(:mandate)) }
    let(:service) { instance_double(Domain::MandateFunnel::Conversion) }

    context "when conversion succeeds" do
      before do
        allow(Domain::MandateFunnel::Conversion).to receive(:new).with(lead.mandate).and_return(service)
        allow(service).to receive(:execute!).and_return(true)

        post :convert, params: {id: lead, locale: :de}
      end

      it "calls Domain::MandateFunnel::Conversion#execute!" do
        expect(service).to have_received(:execute!)
      end

      it { is_expected.to set_flash[:notice] }
    end

    context "when lead conversion goes wrong" do
      context "ActiveRecord::RecordNotDestroyed" do
        before do
          allow(Domain::MandateFunnel::Conversion).to receive(:new).with(lead.mandate).and_return(service)
          allow(service).to receive(:execute!).and_raise(ActiveRecord::RecordNotDestroyed)
          request.env["HTTP_REFERER"] = admin_leads_path

          post :convert, params: {id: lead, locale: :de}
        end

        it { is_expected.to rescue_from(ActiveRecord::RecordNotDestroyed).with(:flash_error) }
      end
    end

    context "ActiveRecord::RecordInvalid" do
      before do
        allow(Domain::MandateFunnel::Conversion).to receive(:new).with(lead.mandate).and_return(service)
        allow(service).to receive(:execute!).and_raise(ActiveRecord::RecordNotDestroyed)
        request.env["HTTP_REFERER"] = admin_leads_path

        post :convert, params: {id: lead, locale: :de}
      end

      it { is_expected.to rescue_from(ActiveRecord::RecordInvalid).with(:flash_error) }
    end
  end
end
