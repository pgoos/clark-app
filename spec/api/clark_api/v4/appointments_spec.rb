# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Appointments, :integration do
  context "when logged in and appointment is present" do
    let(:admin) { create(:admin, first_name: "Helmut") }
    let(:user) { create(:user, :with_mandate) }
    let(:opportunity) { create(:opportunity, admin: admin, category: category) }
    let(:category) { create(:category) }

    before do
      create(:category_retirement)
      login_as(user, scope: :user)
    end

    it "should expose an appointment" do
      current_time = Time.zone.now

      appointment = create(
        :appointment,
        state: "requested",
        starts: current_time + 1.day,
        ends: current_time + 2.day,
        call_type: "phone",
        appointable: opportunity,
        mandate: user.mandate
      )

      json_get_v4 "/api/appointments"
      expect(response.status).to eq(200)

      expected = [
        {
          id: appointment.id,
          state: appointment.state.to_s,
          start_at: appointment.starts,
          end_at: appointment.ends,
          call_type: appointment.call_type,
          consultant_name: admin.first_name,
          category_ident: category.ident,
          category_name: category.name,
          appointable_type: appointment.appointable_type,
          appointable_id: appointment.appointable_id
        }
      ].to_json

      expect(response.body).to eq(expected)
    end
  end

  context "errors" do
    it "returns HTTP 401 if the user is not signed in" do
      json_get_v4 "/api/appointments"
      expect(response.status).to eq(401)
    end
  end
end
