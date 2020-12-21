# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Appointment::Interactors::CancelAppointmentFromSalesforce do
  it "calls AppointmentRepository to cancel appointment" do
    expect_any_instance_of(
      Sales::Constituents::Appointment::Repositories::AppointmentRepository
    ).to receive(:cancel_from_salesforce!).with(1)

    subject.call(1)
  end
end
