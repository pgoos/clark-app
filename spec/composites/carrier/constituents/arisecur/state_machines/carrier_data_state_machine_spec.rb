# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/state_machines/carrier_data_state_machine.rb"

RSpec.describe Carrier::Constituents::Arisecur::StateMachines::CarrierDataStateMachine do
  describe ".fire_event!" do
    describe ":register!" do
      it "transitions to document_transferred" do
        state = described_class.fire_event!("customer_created", :product_created)
        expect(state).to eq "product_created"
      end

      it "throws an error if transition can't be done" do
        expect { described_class.fire_event!("customer_created", :complete) }.to \
          raise_error described_class::InvalidTransition
      end
    end
  end
end
