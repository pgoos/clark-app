# frozen_string_literal: true

# == Schema Information
#
# Table name: business_events
#
#  id                 :integer          not null, primary key
#  person_id          :integer
#  person_type        :string
#  entity_id          :integer
#  entity_type        :string
#  action             :string
#  created_at         :datetime
#  metadata           :jsonb
#  audited_mandate_id :integer
#

require "rails_helper"

RSpec.describe BusinessEvent, :business_events, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes

  include_examples "between_scopeable", :created_at

  # Associations
  # Nested Attributes
  # Validations
  # Callbacks
  # Instance Methods
  # Class Methods

  context "BusinessEvent.audit" do
    before { BusinessEvent.audit_person = create(:admin) }

    let(:entity) { OpenStruct.new(id: 123, changes: {}, previous_changes: {}) }

    it "creates a business event for the given action" do
      expect(BusinessEvent).to receive(:create).with({
                                                       person: Admin.last,
        entity: entity,
        action: "create",
        metadata: {},
        audited_mandate: nil
                                                     })

      BusinessEvent.audit(entity, "create")
    end

    it "adds changes to metadata when action is not create" do
      entity.changes = { field: %w[old new] }

      expect(BusinessEvent).to receive(:create).with({
                                                       person: Admin.last,
        entity: entity,
        action: "update",
        metadata: { field: { old: "old", new: "new" } },
        audited_mandate: nil
                                                     })

      BusinessEvent.audit(entity, "update")
    end

    it "adds previous_changes to metadata when action is not create" do
      entity.previous_changes = { field: %w[old new] }

      expect(BusinessEvent).to receive(:create).with({
                                                       person: Admin.last,
        entity: entity,
        action: "update",
        metadata: { field: { old: "old", new: "new" } },
        audited_mandate: nil
                                                     })

      BusinessEvent.audit(entity, "update")
    end

    BusinessEvent::FILTERED_ATTRIBUTES.each do |attribute|
      [%w[old new], ["", "new"], ["old", ""], ["", ""]].each do |sample|
        it "filters #{attribute}" do
          expected = {
            old: sample.first.blank? ? "" : "********",
            new: sample.last.blank?  ? "" : "********"
          }

          entity.changes = { attribute.to_sym => sample }

          allow(BusinessEvent).to receive(:create)

          BusinessEvent.audit(entity, "update")

          expect(BusinessEvent).to have_received(:create).with(
            person:          Admin.last,
            entity:          entity,
            action:          "update",
            metadata:        { attribute.to_sym => expected },
            audited_mandate: nil
          )
        end
      end
    end

    BusinessEvent::IGNORED_ATTRIBUTES.each do |attribute|
      it "ignores #{attribute}" do
        entity.changes = { attribute.to_sym => %w[old new] }

        expect(BusinessEvent).to receive(:create).with({
                                                         person:          Admin.last,
                                                         entity:          entity,
                                                         action:          "update",
                                                         metadata:        {},
                                                         audited_mandate: nil
                                                       })

        BusinessEvent.audit(entity, "update")
      end
    end

    it "associates an audited mandate if available" do
      entity.audited_mandate = FactoryBot.build(:mandate)

      expect(BusinessEvent).to receive(:create).with({
                                                       person: Admin.last,
        entity: entity,
        action: "update",
        metadata: {},
        audited_mandate: entity.audited_mandate
                                                     })

      BusinessEvent.audit(entity, "update")
    end

    it "injects metadata" do
      expect(BusinessEvent).to receive(:create).with({
                                                       person: Admin.last,
        entity: entity,
        action: "create",
        metadata: { key1: "value 1" },
        audited_mandate: nil
                                                     })

      BusinessEvent.audit(entity, "create", key1: "value 1")
    end

    it "does not override regular metadata, if data is injected" do
      entity.previous_changes = { field: %w[old new] }

      expect(BusinessEvent).to receive(:create).with({
                                                       person: Admin.last,
        entity: entity,
        action: "update",
        metadata: { field: { old: "old", new: "new" } },
        audited_mandate: nil
                                                     })

      BusinessEvent.audit(entity, "update", field: "should not have effect")
    end

    context "integration" do
      let(:real_entity) { create(:user) }

      before do
        real_entity.update(password: "Test1234")
        BusinessEvent.audit(real_entity, "update")
      end

      it "has filtered metadata" do
        expected_log = { "encrypted_password" => { "new" => "********", "old" => "********" } }
        expect(BusinessEvent.last.metadata).to eq(expected_log)
      end
    end
  end

  context "salesforce event callbacks" do
    context "enable_send_events is true" do
      before do
        allow(Settings.salesforce).to receive(:enable_send_events).and_return(true)
      end

      it "triggers 'Mandate accept' salesforce event" do
        mandate = create(:mandate, :accepted)
        event = build(:business_event, entity_type: "Mandate", entity_id: mandate.id, action: "accept")

        expect { event.save }.to have_enqueued_job.on_queue("salesforce")
      end

      it "triggers 'Mandate revoke' salesforce event" do
        mandate = create(:mandate, :revoked)
        event = build(:business_event, entity_type: "Mandate", entity_id: mandate.id, action: "revoke")

        expect { event.save }.to have_enqueued_job.on_queue("salesforce")
      end

      it "triggers 'Appointment create' salesforce event" do
        event = build(:business_event, entity_type: "Appointment", entity_id: 1, action: "create")

        expect { event.save }.to have_enqueued_job.on_queue("salesforce")
      end

      it "triggers 'Appointment accept' salesforce event" do
        event = build(:business_event, entity_type: "Appointment", entity_id: 1, action: "accept")

        expect { event.save }.to have_enqueued_job.on_queue("salesforce")
      end

      it "triggers 'Appointment cancel' salesforce event" do
        event = build(:business_event, entity_type: "Appointment", entity_id: 1, action: "cancel")

        expect { event.save }.to have_enqueued_job.on_queue("salesforce")
      end
    end

    context "enable_send_events is false" do
      before do
        allow(Settings.salesforce).to receive(:enable_send_events).and_return(false)
      end

      it "does NOT trigger 'Mandate accept' salesforce event" do
        event = build(:business_event, entity_type: "Mandate", entity_id: 1, action: "accept")

        expect { event.save }.not_to have_enqueued_job.on_queue("salesforce")
      end
    end

    it "perform delay job if enable_send_events true and action update_address" do
      allow(Settings.salesforce).to receive(:enable_send_events).and_return(true)
      mandate = create(:mandate, :accepted)
      event = build(:business_event, entity_type: "Mandate", entity_id: mandate.id, action: "update_address")
      expect { event.save }.to have_enqueued_job.on_queue("salesforce")
    end

    it "perform delay job if enable_send_events true and action update" do
      allow(Settings.salesforce).to receive(:enable_send_events).and_return(true)
      mandate = create(:mandate, :accepted)
      event = build(:business_event, entity_type: "Mandate", entity_id: mandate.id, action: "update")
      expect { event.save }.to have_enqueued_job.on_queue("salesforce")
    end
  end
end
