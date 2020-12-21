# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Appointment::Interactors::ScheduleAppointment do
  let(:customer_id) { 1 }
  let(:interactor) { described_class.new(appointment_repo: repository) }
  let(:contact) { { phone: "+49 176 55750431", first_name: "John", last_name: "Doe" } }
  let(:dummy_params) { { customer_id: customer_id, starts: Time.current, contact: contact } }
  let(:repository) { instance_double("Sales::Constituents::Appointment::Repositories::AppointmentRepository") }

  context "when a valid statregy is passed in" do
    let(:strategy) { { name: "force-create" } }
    let(:dummy_params) do
      {
        customer_id: customer_id,
        starts: Time.current,
        appointable_type: "FakeType",
        contact: contact,
        strategy: strategy
      }
    end
    let(:fake_result) { double("FakeResult", type: "FakeType", topic: double(id: 123)) }

    it "builds a new topic and stores an appointment with appointable params" do
      expected_params = dummy_params.merge(
        appointable_id: 123,
        appointable_type: "FakeType"
      )

      expect(Sales).to receive(:build_topic).with("FakeType", strategy, customer_id).and_return(fake_result)
      expect(repository).to receive(:schedule_appointment!).with(customer_id, expected_params)

      interactor.call(dummy_params)
    end
  end

  context "when an invalid statregy is passed in" do
    let(:dummy_params) { { strategy: { name: "INVALID_STRATEGY" } } }

    it "returns an error result" do
      result = interactor.call(dummy_params)

      expect(result).not_to be_success
      expect(result.errors).to be_present
    end
  end

  context "when no statregy is passed in" do
    let(:dummy_params) do
      {
        customer_id: customer_id,
        starts: Time.current,
        appointable_id: 123,
        contact: contact,
        appointable_type: "FakeType"
      }
    end

    it "checks appointable and store a new appointment" do
      expected_params = dummy_params.merge(
        appointable_id: 123,
        appointable_type: "FakeType"
      )

      expect(repository).to receive(:valid_appointable?).with("FakeType", 123, customer_id).and_return(true)
      expect(repository).to receive(:schedule_appointment!).with(customer_id, expected_params)

      interactor.call(dummy_params)
    end

    context "with a valid appointable" do
      before do
        allow(repository).to receive(:valid_appointable?).and_return(true)
      end

      it "call repository to create a new appointment" do
        expect(repository).to receive(:schedule_appointment!).with(customer_id, dummy_params).and_return(nil)

        interactor.call(dummy_params)
      end
    end

    context "with an invalid appointable" do
      before do
        allow(repository).to receive(:valid_appointable?).and_return(false)
      end

      it "returns an error result" do
        expect(repository).not_to receive(:schedule_appointment!).with(customer_id, dummy_params)

        result = interactor.call(dummy_params)

        expect(result).not_to be_success
        expect(result.errors).to be_present
      end
    end
  end

  context "when something goes wrong" do
    let(:contact) { { phone: "INVALID PHONE NUMBER" } }

    it "handles the exception and return an error result" do
      result = interactor.call(dummy_params)

      expect(result).not_to be_success
      expect(result.errors).to be_present
    end
  end
end
