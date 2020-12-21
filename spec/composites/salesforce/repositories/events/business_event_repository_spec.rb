# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/business_event_repository"

RSpec.describe Salesforce::Repositories::Events::BusinessEventRepository do
  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }

  context "Mandate accept" do
    let!(:mandate_accept_business_event) { create(:business_event, entity: mandate, action: "accept") }

    describe "#find" do
      it "returns event" do
        event = repository.find(mandate_accept_business_event.id, "Mandate", "accept")
        expect(event.id).to eq mandate_accept_business_event.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "customer"
        expect(event.aggregate_id).to eq mandate_accept_business_event.entity_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "customer-accepted"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end

      context "when event does not exist" do
        it "returns nil" do
          expect(repository.find(9999, "Mandate", "accept")).to be_nil
        end
      end
    end
  end

  context "Mandate revoke" do
    let!(:mandate_accept_business_event) { create(:business_event, entity: mandate, action: "revoke") }

    describe "#find" do
      it "returns event" do
        event = repository.find(mandate_accept_business_event.id, "Mandate", "revoke")
        expect(event.id).to eq mandate_accept_business_event.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "customer"
        expect(event.aggregate_id).to eq mandate_accept_business_event.entity_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "customer-revoked"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end

      context "when event does not exist" do
        it "returns nil" do
          expect(repository.find(9999, "Mandate", "revoke")).to be_nil
        end
      end
    end
  end

  context "Mandate update" do
    let!(:mandate_update_business_event) { create(:business_event, entity: mandate, action: "update") }

    describe "#find" do
      it "returns update event" do
        event = repository.find(mandate_update_business_event.id, "Mandate", "update")
        expect(event.id).to eq mandate_update_business_event.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "customer"
        expect(event.aggregate_id).to eq mandate_update_business_event.entity_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "customer-updated"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end

      context "when event does not exist" do
        it "returns nil" do
          expect(repository.find(9999, "Mandate", "accept")).to be_nil
        end
      end
    end
  end

  context "Appointment create" do
    let!(:appointment) { create(:appointment, mandate: mandate, state: :requested) }
    let!(:appointment_created_business_event) { create(:business_event, entity: appointment, action: "create") }

    describe "#find" do
      it "returns event" do
        event = repository.find(appointment_created_business_event.id, "Appointment", "create")
        expect(event.id).to eq appointment_created_business_event.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "appointment"
        expect(event.aggregate_id).to eq appointment_created_business_event.entity_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "appointment-created"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end

      context "when event does not exist" do
        it "returns nil" do
          expect(repository.find(9999, "Appointment", "create")).to be_nil
        end
      end
    end
  end

  context "Appointment accept" do
    let!(:appointment) { create(:appointment, mandate: mandate, state: :accepted) }
    let!(:appointment_created_business_event) { create(:business_event, entity: appointment, action: "accept") }

    describe "#find" do
      it "returns event" do
        event = repository.find(appointment_created_business_event.id, "Appointment", "accept")
        expect(event.id).to eq appointment_created_business_event.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "appointment"
        expect(event.aggregate_id).to eq appointment_created_business_event.entity_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "appointment-confirmed"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end

      context "when event does not exist" do
        it "returns nil" do
          expect(repository.find(9999, "Appointment", "accept")).to be_nil
        end
      end
    end
  end

  context "Appointment cancel" do
    let!(:appointment) { create(:appointment, mandate: mandate, state: :cancelled) }
    let!(:appointment_created_business_event) { create(:business_event, entity: appointment, action: "cancel") }

    describe "#find" do
      it "returns event" do
        event = repository.find(appointment_created_business_event.id, "Appointment", "cancel")
        expect(event.id).to eq appointment_created_business_event.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "appointment"
        expect(event.aggregate_id).to eq appointment_created_business_event.entity_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "appointment-cancelled"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end

      context "when event does not exist" do
        it "returns nil" do
          expect(repository.find(9999, "Appointment", "cancel")).to be_nil
        end
      end
    end
  end
end
