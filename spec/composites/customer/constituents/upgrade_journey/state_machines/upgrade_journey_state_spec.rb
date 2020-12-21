# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/upgrade_journey/state_machines/upgrade_journey_state"

RSpec.describe Customer::Constituents::UpgradeJourney::StateMachines::UpgradeJourneyState do
  describe ".fire_event!" do
    it "transitions to signature" do
      state = described_class.fire_event!("profile", :update_profile)
      expect(state).to eq "signature"
    end

    it "transitions to finished" do
      state = described_class.fire_event!("signature", :confirm_signature)
      expect(state).to eq "finished"
    end

    it "throws an error if transition can't be done" do
      expect { described_class.fire_event!("profile", :confirm_signature) }.to \
        raise_error described_class::InvalidTransition
    end
  end
end
