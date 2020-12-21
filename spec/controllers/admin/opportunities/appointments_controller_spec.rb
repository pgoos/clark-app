# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Opportunities::AppointmentsController, :integration, type: :request do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/opportunities/appointments")) }
  let(:admin) { create(:admin, role: role) }
  let(:opportunity) { create(:opportunity) }

  before { sign_in(admin) }

  describe "GET /new" do
    it "renders page" do
      get new_admin_opportunity_appointment_path(opportunity_id: opportunity.id, locale: :de)

      expect(response).to be_successful
      expect(response.body).to include("Termin erstellen")
    end
  end

  describe "POST /create" do
    let!(:time) { 1.day.from_now.change(hour: 10) }
    let(:parameters) do
      {
        "appointment" => {
          "starts(3i)" => time.day, "starts(2i)" => time.month, "starts(1i)" => time.year,
          "starts(4i)" => time.hour, "starts(5i)" => time.min,
          "ends(3i)" => time.day, "ends(2i)" => time.month, "ends(1i)" => time.year,
          "ends(4i)" => time.hour, "ends(5i)" => time.min,
          "call_type" => "phone", "appointable_id" => opportunity.id, "appointable_type" => "Opportunity",
          "mandate_id" => opportunity.mandate.id
        }
      }
    end

    context "when Customer does not have existing accepted appointments" do
      it "creates appointment" do
        post admin_opportunity_appointments_path(
          opportunity_id: opportunity.id,
          appointment: parameters["appointment"],
          locale: :de
        )

        expect(response).to redirect_to(admin_opportunity_path(opportunity))
        expect(opportunity.appointments.requested.phone.where(starts: time, ends: time)).to exist
        expect(request.flash[:notice]).to eq(
          "Dein Termin für diese Gelegenheit wurde erfolgreich angelegt."\
          " Vergiss nicht deinen Kalender zu updaten."
        )
      end
    end

    context "when Customer has existing accepted appointments" do
      let!(:appointment) { create(:appointment, :accepted, appointable: opportunity, starts: 1.days.from_now) }

      it "does not create appointment" do
        post admin_opportunity_appointments_path(
          opportunity_id: opportunity.id,
          appointment: parameters["appointment"],
          locale: :de
        )

        expect(response).to redirect_to(admin_opportunity_path(opportunity))
        expect(opportunity.appointments.requested.phone.where(starts: time, ends: time)).not_to exist
        expect(request.flash[:notice]).to eq("Du hast bereits einen Termin für diese Gelegenheit.")
      end
    end
  end
end
