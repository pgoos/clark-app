# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Appointment::Interactors::ScheduleAcceptedAppointmentFromSalesforce do
  context "when correct params are passed in" do
    let(:dummy_params) { { customer_id: 1, starts: Time.current } }

    before do
      allow_any_instance_of(
        Sales::Constituents::Appointment::Repositories::AppointmentRepository
      ).to receive(:valid_appointable?).and_return(true)

      allow_any_instance_of(
        Sales::Constituents::Appointment::Repositories::AppointmentRepository
      ).to receive(:appointable_assigned?).and_return(true)
    end

    it "call AppointmentRepository to schedule appointment" do
      expect_any_instance_of(
        Sales::Constituents::Appointment::Repositories::AppointmentRepository
      ).to receive(:schedule_accepted_appointment!).with(dummy_params[:customer_id], dummy_params)

      described_class.new.call(dummy_params)
    end
  end

  context "when neccessary params are not passed in" do
    it "Interactor handles exception and return error" do
      expect_any_instance_of(
        Sales::Constituents::Appointment::Repositories::AppointmentRepository
      ).to receive(:valid_appointable?).and_raise(
        Utils::Repository::Errors::ValidationError
      )
      result = described_class.new.call({})

      expect(result).not_to be_success
      expect(result.errors).to be_present
    end
  end
end
