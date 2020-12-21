# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppointmentsRepository, :integration do
  let(:mandate) { create(:mandate, :accepted) }
  let(:opportunity_with_retirement_category) { create(:opportunity, :with_retirement_category) }

  describe "#retrieve_upcoming_appointments" do
    it "return only upcoming appointments" do
      from_another_mandate = create(:appointment, :requested, starts: Time.now + 2.day)
      old_appointment = create(:appointment, :accepted, mandate: mandate, starts: Time.now - 1.day)
      retirement = create(
        :appointment,
        :accepted,
        mandate: mandate,
        appointable: opportunity_with_retirement_category,
        starts: Time.now + 3.day
      )

      create(:appointment, :accepted, mandate: mandate, starts: Time.now + 1.day)
      create(:appointment, :requested, mandate: mandate, starts: Time.now + 2.day)

      appointments = described_class.retrieve_upcoming_appointments(mandate.id)

      expect(appointments.length).to be(2)
      expect(appointments).not_to include(retirement)
      expect(appointments).not_to include(old_appointment)
      expect(appointments).not_to include(from_another_mandate)
      expect(appointments).to all(be_kind_of(Structs::Appointment))
    end
  end
end
