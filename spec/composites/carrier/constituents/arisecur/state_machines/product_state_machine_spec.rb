# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/state_machines/product_state_machine.rb"

RSpec.describe Carrier::Constituents::Arisecur::StateMachines::ProductStateMachine do
  describe ".fire_event!" do
    describe ":register!" do
      it "transitions to document_transferred" do
        state = described_class.fire_event!("details_available", :request_takeover)
        expect(state).to eq "takeover_requested"
      end

      it "throws an error if transition can't be done" do
        expect { described_class.fire_event!("takeover_requested", :request_takeover) }.to \
          raise_error described_class::InvalidTransition
      end
    end
  end
end
