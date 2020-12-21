# frozen_string_literal: true

require "rails_helper"

describe ProductCollectionDecorator, type: :decorator do
  subject { Product.decorate }

  describe ".available_states" do
    context "when self_service_products feature is on" do
      before do
        allow(Settings).to receive_message_chain(:app_features, :self_service_products) { true }
      end

      it "includes all states" do
        expect(subject.available_states).to include(*Product.state_machine.states)
      end
    end

    context "when self_service_products feature is off" do
      before do
        allow(Settings).to receive_message_chain(:app_features, :self_service_products) { false }
      end

      it "includes base states" do
        expect(subject.available_states).to \
          include(*Product.state_machine.states)
      end
    end
  end
end
