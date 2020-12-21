# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Appointment::Interactors::FindAppointmentWithState do
  let(:appointment_id) { 1 }
  let(:appointment_state) { "requested" }

  it "calls AppointmentRepository to find an appointment" do
    expect_any_instance_of(
      Sales::Constituents::Appointment::Repositories::AppointmentRepository
    ).to receive(:find_appointment_with_state).with(appointment_id, appointment_state)

    subject.call(appointment_id, appointment_state)
  end
end
