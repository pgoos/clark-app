# frozen_string_literal: true

require "rails_helper"
require "composites/customer/state_machines/customer_state_machine"

RSpec.describe Customer::StateMachines::CustomerStateMachine do
  describe ".fire_event!" do
    describe ":register!" do
      it "transitions to self_service" do
        state = described_class.fire_event!("prospect", :register)
        expect(state).to eq "self_service"
      end

      it "throws an error if transition can't be done" do
        expect { described_class.fire_event!("self_service", :register) }.to \
          raise_error described_class::InvalidTransition
        expect { described_class.fire_event!("mandate_customer", :register) }.to \
          raise_error described_class::InvalidTransition
      end
    end
  end
end
