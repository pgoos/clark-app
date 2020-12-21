# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::NPSAvailabilityChecker do
  let(:mandates_repository) { class_double(MandatesRepository) }
  let(:nps_cycles_repository) { class_double(NPSCyclesRepository) }
  let(:nps_interactions_repository) { class_double(NPSInteractionsRepository) }
  let(:service) { described_class.new(mandates_repository, nps_cycles_repository, nps_interactions_repository) }

  describe "#call" do
    before do
      allow(mandates_repository)
        .to receive(:find).and_return mandate
      allow(mandates_repository)
        .to receive(:older_than_14_days?).with(mandate.id).and_return older_than_14_days
      allow(nps_cycles_repository)
        .to receive(:open_cycle?).and_return open_cycle
      allow(nps_interactions_repository)
        .to receive(:any_interaction_in_the_last_6_months?).with(mandate.id).and_return any_interaction
    end

    context "when all requirements are matched" do
      let(:open_cycle) { true }
      let(:any_interaction) { false }
      let(:older_than_14_days) { true }

      context "clark 1 customer" do
        let(:mandate) { double(id: 1, state: "accepted", customer_state: nil) }

        it "returns true" do
          expect(service.call(mandate.id)).to be true
        end
      end

      context "clark 2 customer as self_serivce" do
        let(:mandate) { double(id: 1, state: "created", customer_state: "self_service") }

        it "returns true" do
          expect(service.call(mandate.id)).to be true
        end
      end

      context "clark 2 customer as mandate_customer" do
        let(:mandate) { double(id: 1, state: "created", customer_state: "mandate_customer") }

        it "returns true" do
          expect(service.call(mandate.id)).to be true
        end
      end
    end

    context "when customer state is prospect" do
      let(:open_cycle) { true }
      let(:any_interaction) { false }
      let(:older_than_14_days) { true }
      let(:mandate) { double(id: 1, customer_state: "prospect", state: "created") }

      it "returns false" do
        expect(service.call(mandate.id)).to be false
      end
    end

    context "when customer is not old enough" do
      let(:open_cycle) { true }
      let(:any_interaction) { false }
      let(:older_than_14_days) { false }
      let(:mandate) { double(id: 1, customer_state: "customer_state", state: "accepted") }

      it "returns false" do
        expect(service.call(mandate.id)).to be false
      end
    end

    context "when customer has an interaction" do
      let(:open_cycle) { true }
      let(:any_interaction) { true }
      let(:older_than_14_days) { true }
      let(:mandate) { double(id: 1, customer_state: "customer_state", state: "accepted") }

      it "returns false" do
        expect(service.call(mandate.id)).to be false
      end
    end

    context "when there is no open cycle" do
      let(:open_cycle) { false }
      let(:any_interaction) { false }
      let(:older_than_14_days) { true }
      let(:mandate) { double(id: 1, customer_state: "self_service", state: "created") }

      it "returns false" do
        expect(service.call(mandate.id)).to be false
      end
    end
  end
end
