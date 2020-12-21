# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/payloads/appointment_cancelled_repository"

RSpec.describe Salesforce::Repositories::Events::Payloads::AppointmentCancelledRepository do
  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:appointment) { create(:appointment, mandate: mandate, state: :cancelled) }
  let!(:business_event) { create(:business_event, entity: appointment, action: "cancel") }

  describe "#wrap" do
    it "returns appointment cancelled event" do
      event = repository.wrap(business_event.entity)
      expect(event.id).to eq business_event.entity_id
      expect(event.state).to eq appointment.state
      expect(event.opportunity_id).to eq appointment.appointable_id
      expect(event.customer_id).to eq mandate.id
      expect(event.method_of_contact).to eq appointment.method_of_contact
      expect(event.starts).to eq appointment.starts.rfc3339
      expect(event.ends).to eq appointment.ends&.rfc3339
      expect(event.subject)
        .to eq "Meeting mit #{mandate.first_name} #{mandate.last_name} über #{appointment.appointable.category_name}"

      expect(event).to be_kind_of Salesforce::Entities::Events::AppointmentCancelled
    end

    context "when event does not exist" do
      it "returns nil" do
        expect(repository.wrap(nil)).to be_nil
      end
    end
  end
end
