# frozen_string_literal: true

require "spec_helper"

require "lifters/domain/appointments/retrieve_upcoming_appointments"

RSpec.describe Domain::Appointments::RetrieveUpcomingAppointments do
  describe "#call" do
    let(:mandate_id) { 1 }
    let(:appointments_repository) { class_double("AppointmentsRepository") }
    let(:service) do
      described_class.new(
        appointments_repository: appointments_repository
      )
    end

    context "when there are appointments" do
      it "returns appointments" do
        allow(appointments_repository).to receive(:retrieve_upcoming_appointments).and_return([Object.new])

        result = service.call(customer_id: mandate_id)
        expect(result.length).to be(1)
      end

      it "call repository for upcoming appointments" do
        expect(appointments_repository).to receive(:retrieve_upcoming_appointments).with(mandate_id)

        service.call(customer_id: mandate_id)
      end

      it "raises an exception when customer id is empty" do
        expect {
          service.call(customer_id: nil)
        }.to raise_error(ArgumentError, "Customer ID can not be nil")
      end
    end

    context "when there aren't appointments" do
      it "returns empty" do
        allow(appointments_repository).to receive(:retrieve_upcoming_appointments).and_return([])

        result = service.call(customer_id: mandate_id)
        expect(result.length).to be(0)
      end
    end
  end
end
