# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Appointment::Interactors::AcceptAppointment do
  context "when appointment in the requested state" do
    it "calls AppointmentRepository to accept appointment" do
      expect_any_instance_of(
        Sales::Constituents::Appointment::Repositories::AppointmentRepository
      ).to receive(:accept!).with(1)

      subject.call(1)
    end
  end

  context "when appointment in the canceled state" do
    it "calls AppointmentRepository to cancel appointment" do
      allow_any_instance_of(
        Sales::Constituents::Appointment::Repositories::AppointmentRepository
      ).to receive(:accept!).and_return(nil)

      result = subject.call(1)

      expect(result).not_to be_success
      expect(result.errors).to be_present
      expect(result.errors).to eq([I18n.t("composites.sales.constituents.appointments.not_accepted")])
    end
  end
end
