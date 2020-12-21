# frozen_string_literal: true

require "rails_helper"

require "composites/customer/constituents/surveys/repositories/nps_cycle_repository"
require "composites/customer/constituents/surveys/interactors/reset_nps_cycle"

RSpec.describe Customer::Constituents::Surveys::Interactors::ResetNPSCycle do
  let(:settings) { double(maximum_score: 300, duration_in_days: 7) }
  let(:interactor) { described_class.new(cycles_repo: cycle_repository) }
  let(:cycle_repository) do
    instance_double(Customer::Constituents::Surveys::Repositories::NPSCycleRepository)
  end

  describe "#call" do
    shared_examples "a valid reset operation" do
      let(:cycle) { double(id: 123, state: current_state) }

      it "calls repository" do
        end_at = (Time.current + 7.days).change(hour: 8, minutes: 0)
        expect(cycle_repository).to receive(:current_cycle).and_return cycle
        expect(cycle_repository).to receive(:update_cycle_state!).with(cycle.id, "CLOSED")
        expect(cycle_repository).to receive(:open_new_cycle!).with(maximum_score: 300, end_at: end_at)

        result = interactor.call(settings)
        expect(result.ok?).to be true
      end
    end

    context "when current cycle is a OPEN cycle" do
      let(:current_state) { "OPEN" }

      it_behaves_like "a valid reset operation"
    end

    context "when current cycle is a CLOSING cycle" do
      let(:current_state) { "CLOSING" }

      it_behaves_like "a valid reset operation"
    end

    context "when there is no current cycle" do
      before do
        allow(cycle_repository).to receive(:current_cycle).and_return nil
      end

      it "calls repository" do
        end_at = (Time.current + 7.days).change(hour: 8, minutes: 0)
        expect(cycle_repository).not_to receive(:update_cycle_state!)
        expect(cycle_repository).to receive(:open_new_cycle!).with(maximum_score: 300, end_at: end_at)

        result = interactor.call(settings)
        expect(result.ok?).to be true
      end
    end

    context "when something goes wrong" do
      before do
        allow(cycle_repository).to receive(:current_cycle).and_raise StandardError, "Whoops!"
      end

      it "catches the error and returns it" do
        result = interactor.call(settings)
        expect(result.ok?).to be false
        result.on_failure { |error| expect(error.message).to eq("Whoops!") }
      end
    end
  end
end
