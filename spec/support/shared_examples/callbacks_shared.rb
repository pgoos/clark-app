# frozen_string_literal: true
RSpec.shared_examples "callbacks_shared" do
  context "when no lead or user is in session" do
    let(:current_visit) { create(:tracking_visit, utm_params) }
    let(:utm_params) do
      {
        utm_source:   "utm source",
        utm_medium:   "utm medium",
        utm_term:     "utm term",
        utm_content:  "utm content",
        utm_campaign: "utm campaign"
      }
    end

    before do
      allow_any_instance_of(ContactsController).to receive(:current_visit).and_return(current_visit)
    end

    context "when no email is given for lead" do
      before { params.delete("email") }

      it "sends an email and creates an new anonymous lead with utm params from current visit and mandate" do
        expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
          .and change { Lead.count }.by(1)
          .and change { Mandate.count }.by(1)
        expect(Lead.last.source_data).to include(utm_params.stringify_keys)
        expect(Lead.last.source_data).to include("anonymous_lead" => true)
      end
    end

    context "when no lead with given email exists" do
      it "sends an email and creates an new lead with utm params from current visit and mandate" do
        expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
          .and change { Lead.count }.by(1)
          .and change { Mandate.count }.by(1)
        expect(Lead.last.source_data).to eq(utm_params.stringify_keys)
      end
    end

    context "when lead with given email exists in DB" do
      before { create(:lead, :with_mandate, email: params["email"]) }

      it "sends an email but does not create a new lead" do
        expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
          .and not_change { Lead.count }
          .and not_change { Mandate.count }
      end
    end
  end

  context "when lead is in session" do
    let(:lead) { create(:lead, :with_mandate) }
    before     { request.env["warden"].set_user(lead, scope: :lead) }

    it "sends an email" do
      expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
        .and not_change { Lead.count }
        .and not_change { Mandate.count }
    end
  end

  context "when user is in session" do
    let(:user) { create(:user, :with_mandate, email: user_email) }
    before     { request.env["warden"].set_user(user, scope: :user) }

    context "when user provided email from his profile" do
      let(:user_email) { params["email"] }

      it "sends an email" do
        expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
          .and not_change { Lead.count }
          .and not_change { Mandate.count }
      end
    end
  end
end
