# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Appointment::Repositories::AppointmentRepository, :integration do
  let(:valid_params) do
    {
      starts: Time.current,
      ends: Time.current,
      method_of_contact: "phone",
      appointable_id: opportunity.id,
      appointable_type: opportunity.class.name
    }
  end

  describe "#schedule_appointment!" do
    let(:mandate) { create(:mandate) }
    let(:opportunity) { create(:opportunity) }

    context "when correct params are passed in" do
      it "creates appointment" do
        repo =
          described_class.new.schedule_appointment!(
            mandate.id,
            **valid_params
          )

        created_appointment = Appointment.find_by(
          mandate: mandate,
          appointable: opportunity,
          method_of_contact: "phone"
        )

        expect(repo).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(created_appointment).to be_truthy
        expect(created_appointment.state).to eq("requested")
      end
    end

    context "when incorrect params are passed in" do
      it "raises exception" do
        expect {
          described_class.new.schedule_appointment!(mandate.id, {})
        }.to raise_error(Utils::Repository::Errors::ValidationError)
      end
    end
  end

  describe "#schedule_accepted_appointment!" do
    let(:mandate) { create(:mandate) }
    let(:opportunity) { create(:opportunity) }

    context "when correct params are passed in" do
      it "creates and accepts an appointment" do
        repo =
          described_class.new.schedule_accepted_appointment!(
            mandate.id,
            **valid_params
          )

        accepted_appointment = Appointment.find_by(
          mandate: mandate,
          appointable: opportunity,
          method_of_contact: "phone"
        )

        expect(repo).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(accepted_appointment).to be_truthy
        expect(accepted_appointment.state).to eq("accepted")
      end
    end

    context "when incorrect params are passed in" do
      it "raises exception" do
        expect {
          described_class.new.schedule_accepted_appointment!(mandate.id, {})
        }.to raise_error(Utils::Repository::Errors::ValidationError)
      end
    end
  end

  describe "#valid_appointable?" do
    let(:mandate) { create(:mandate) }
    let!(:opportunity) { create(:opportunity, mandate: mandate) }

    context "when appointable belongs to customer" do
      it "returns true" do
        result =
          described_class.new.valid_appointable?(Opportunity.name, opportunity.id, mandate.id)

        expect(result).to be_truthy
      end
    end

    context "when appointable does not belongs to customer" do
      it "returns false" do
        result =
          described_class.new.valid_appointable?(Opportunity.name, 199, mandate.id)

        expect(result).to be_falsey
      end
    end
  end

  describe "#appointable_assigned?" do
    let(:mandate) { create(:mandate) }
    let!(:opportunity) { create(:opportunity, mandate: mandate) }

    context "when appointable is assigned to the admin" do
      it "returns true" do
        result =
          described_class.new.appointable_assigned?(Opportunity.name, opportunity.id, mandate.id)

        expect(result).to be_truthy
      end
    end

    context "when appointable does not assigned to the admin" do
      before do
        opportunity.update!(admin_id: nil)
      end

      it "returns false" do
        result =
          described_class.new.appointable_assigned?(Opportunity.name, opportunity.id, mandate.id)

        expect(result).to be_falsey
      end
    end
  end

  describe "#accept!" do
    let(:mandate) { create(:mandate) }
    let(:opportunity) { create(:opportunity) }
    let(:appointment) { create(:appointment, appointable: opportunity) }

    context "when appointmet requested" do
      it "accepts appointment" do
        result = subject.accept!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("accepted")
      end

      it "triggered appointment conformation" do
        expect_any_instance_of(
          ::Domain::Appointments::Appointment
        ).to receive(:send_appointment_confirmation)

        subject.accept!(appointment.id)
      end
    end

    context "when appointmet canceled" do
      let(:appointment) { create(:appointment, appointable: opportunity, state: :cancelled) }

      it "does NOT accept appointment" do
        result = subject.accept!(appointment.id)

        expect(result).to be_nil
        expect(appointment.reload.state).to eq("cancelled")
      end
    end
  end

  describe "#accept_from_salesforce!" do
    let(:mandate) { create(:mandate) }
    let(:opportunity) { create(:opportunity) }
    let(:appointment) { create(:appointment, appointable: opportunity) }

    context "when appointmet requested" do
      it "accepts appointment" do
        result = subject.accept_from_salesforce!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("accepted")
      end

      it "triggered appointment conformation" do
        expect_any_instance_of(
          ::Domain::Appointments::Appointment
        ).to receive(:send_appointment_confirmation)

        subject.accept_from_salesforce!(appointment.id)
      end
    end

    context "when appointment canceled" do
      let(:appointment) { create(:appointment, appointable: opportunity, state: :cancelled) }

      it "does NOT accept appointment" do
        result = subject.accept_from_salesforce!(appointment.id)

        expect(result).to be_nil
        expect(appointment.reload.state).to eq("cancelled")
      end
    end

    context "when appointment accepted" do
      let(:appointment) { create(:appointment, appointable: opportunity, state: :accepted) }

      it "returns an appointment" do
        result = subject.accept_from_salesforce!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("accepted")
      end
    end
  end

  describe "#cancel!" do
    let(:mandate) { create(:mandate) }
    let(:opportunity) { create(:opportunity) }
    let(:appointment) { create(:appointment, appointable: opportunity) }

    context "when appointmet requested" do
      it "cancels appointment" do
        result = subject.cancel!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("cancelled")
      end
    end

    context "when appointmet accepted" do
      let(:appointment) { create(:appointment, appointable: opportunity, state: :accepted) }

      it "cancels appointment" do
        result = subject.cancel!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("cancelled")
      end
    end
  end

  describe "#cancel_from_salesforce!" do
    let(:mandate) { create(:mandate) }
    let(:opportunity) { create(:opportunity) }
    let(:appointment) { create(:appointment, appointable: opportunity) }

    context "when appointmet requested" do
      it "cancels appointment" do
        result = subject.cancel_from_salesforce!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("cancelled")
      end
    end

    context "when appointmet accepted" do
      let(:appointment) { create(:appointment, appointable: opportunity, state: :accepted) }

      it "cancels appointment" do
        result = subject.cancel_from_salesforce!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("cancelled")
      end
    end

    context "when appointmet is alredy cancelled" do
      let(:appointment) { create(:appointment, appointable: opportunity, state: :cancelled) }

      it "cancels appointment" do
        result = subject.cancel_from_salesforce!(appointment.id)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq("cancelled")
      end
    end
  end

  describe "#find_appointment_with_state" do
    let(:appointment) { create(:appointment) }

    context "when appointment with state exists" do
      it "returns an appointment" do
        result = subject.find_appointment_with_state(appointment.id, appointment.state)

        expect(result).to be_a(Sales::Constituents::Appointment::Entities::Appointment)
        expect(appointment.reload.state).to eq(appointment.state)
      end
    end

    context "when appointment with state does not exists" do
      it "does not return an appointment" do
        result = subject.find_appointment_with_state(appointment.id, "cancelled")

        expect(result).to be_nil
      end
    end
  end
end
