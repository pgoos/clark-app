# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::SessionsController, :integration, type: :controller do
  # Settings
  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Concerns

  # Filter

  # Actions

  describe "#login" do
    subject do
      post :create, params: {user: {email: user.email, password: user.password}, locale: "de"}
    end

    let(:user) { create(:user, :with_mandate) }
    let(:lead) { create(:lead, :with_mandate) }

    before { user; lead } # create in DB

    context "when no lead is in session" do
      it "logs in user" do
        expect(DeviceLeadConverter).not_to receive(:update_user_from_device_lead)
        expect { subject }.to change { request.env["warden"].user(:user) }.from(nil).to(user)
      end
    end

    context "when lead is in session and has tracking data" do
      let(:tracking_visit) { create(:tracking_visit, mandate: lead.mandate) }
      let(:tracking_event) { create(:tracking_event, mandate: lead.mandate) }
      let(:adjust_event) { create(:tracking_adjust_event, mandate: lead.mandate, params: {key: "value"}) }
      let(:business_event) { create(:business_event, audited_mandate: lead.mandate) }

      before do
        tracking_visit; tracking_event; adjust_event; business_event
        request.env["warden"].set_user(lead, scope: :lead)
      end

      it "logs in user, removes lead from session and lead and mandate from database" do
        expect(DeviceLeadConverter).to receive(:update_user_from_device_lead).with(lead, user).and_call_original

        expect { subject }.to change { request.env["warden"].user(:lead) }.from(lead).to(nil)
                                                                          .and change { Lead.count }.by(-1)
                                                                                                    .and change { Mandate.count }.by(-1)
                                                                                                                                 .and change { request.env["warden"].user(:user) }.from(nil).to(user)
      end
    end

    describe "set_mandate_for_current_visit callback" do
      let(:visit) { create :tracking_visit, mandate: mandate }

      before { allow_any_instance_of(Users::SessionsController).to receive(:current_visit).and_return(visit) }

      context "when current visit has no mandate" do
        let(:mandate) { nil }

        it "sets the mandate of the current_user" do
          expect { subject }.to change { visit.reload.mandate }.from(nil).to(user.mandate)
        end
      end

      context "when current visit has mandate already" do
        let(:mandate) { create :mandate }

        it "does not change the mandate" do
          expect { subject }.not_to change { visit.reload.mandate }
        end
      end
    end
  end
end
