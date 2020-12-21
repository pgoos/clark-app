# encoding : utf-8
# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "migrate_lead_addresses_to_be_active_and_accepted"

describe MigrateLeadAddressesToBeActiveAndAccepted, :integration do
  # THIS LET STATEMENT HAS TO BE EXECUTED FIRST:
  let!(:addresses_not_to_touch) do
    mandate1.addresses << create(:address, active: false, accepted: false)

    # And that one here is the reason, why it has to be executed first. It should be older than the one in the next
    # let statement:
    mandate2.addresses << create(:address, active: false, accepted: false)
    addresses = mandate2.addresses.to_a

    mandates = [mandate1]

    # lead mandates with wrong states:
    mandates += Mandate.state_machine.states.keys.except(*states_to_migrate).map do |state|
      create(:mandate, state: state, lead: new_lead.(), active_address: build(:address, active: false, accepted: false))
    end

    # mandate with a user:
    mandates += [
      create(
        :mandate,
        :in_creation,
        user: create(:user),
        active_address: create(:address, active: false, accepted: false)
      )
    ]

    # This weird way makes sure not to create lots of unused addresses with the nested mandate factory:
    addresses += mandates.map(&:addresses).flatten.compact
    addresses << create(:address, active: false, accepted: false, mandate: nil)
    addresses
  end
  let!(:single_exception_of_active_address) do
    mandate1.addresses << create(:address, active: true, accepted: false)
    mandate1.addresses.last
  end

  # THIS LET STATEMENT HAS TO BE EXECUTED AFTER THE FIRST:
  let!(:address_entities_to_migrate) do
    # combinations of :in_creation mandates with address states to update:
    # rubocop:disable Layout/LineLength
    in_creation_addresses = [
      create(:mandate, :in_creation, lead: new_lead.(), active_address: build(:address, active: false, accepted: false)),
      create(:mandate, :in_creation, lead: new_lead.(), active_address: build(:address, active: false, accepted: true)),
      create(:mandate, :in_creation, lead: new_lead.(), active_address: build(:address, active: true, accepted: false))
    ].map(&:addresses).flatten
    # rubocop:enable Layout/LineLength

    # other mandate states than :in_creation to migrate
    mandate_with_accepted_states = states_to_migrate.except(:in_creation).map do |state|
      create(:mandate, state: state, lead: new_lead.(), active_address: build(:address, active: false, accepted: false))
    end

    # A newer address of a mandate with multiple addresses but none active. It should be made active and accepted.
    mandate2.addresses << create(:address, active: false, accepted: false)

    in_creation_addresses + mandate_with_accepted_states.map(&:addresses).flatten + [mandate2.addresses.order(:id).last]
  end

  let(:already_active_and_accepted) do
    create(:mandate, :in_creation, lead: new_lead.(), active_address: build(:address, active: true, accepted: true))
  end

  let(:mandate1) { create(:mandate, :in_creation, lead: new_lead.(), active_address: nil) }
  let(:mandate2) { create(:mandate, :in_creation, lead: new_lead.(), active_address: nil) }
  let(:already_active_and_accepted_updated_at) { already_active_and_accepted.updated_at }
  let(:states_to_migrate) { Mandate.state_machine.states.keys.except(:freebie, :accepted, :revoked) }
  let(:new_lead) { -> { Lead.new(attributes_for(:lead, mandate: nil).compact) } }

  describe "#data" do
    before do
      already_active_and_accepted_updated_at
      subject.data
    end

    it "should only migrate the right ones" do
      expect(already_active_and_accepted.updated_at).to eq(already_active_and_accepted_updated_at)

      addresses_not_to_touch.each(&:reload)

      expect(addresses_not_to_touch.select(&:active)).to be_empty
      expect(addresses_not_to_touch.select(&:accepted)).to be_empty

      expect(single_exception_of_active_address).to be_active
      expect(single_exception_of_active_address).not_to be_accepted

      address_entities_to_migrate.each(&:reload)
      expect(address_entities_to_migrate).to all(be_active)
      expect(address_entities_to_migrate).to all(be_accepted)
    end
  end

  describe "#rollback" do
    it "does not raise an exception" do
      expect { subject.data }.not_to raise_exception
    end
  end
end
