# frozen_string_literal: true

require "rails_helper"

require "composites/customer/constituents/surveys/repositories/nps_interaction_repository"
require "composites/customer/constituents/surveys/interactors/create_nps_interaction"

RSpec.describe Customer::Constituents::Surveys::Interactors::CreateNPSInteraction do
  let(:interactor) do
    described_class.new(interactions_repo: interaction_repository,
                        close_nps_cycle_if_max_score_exceeds: close_nps_cycle_if_max_score_exceeds_interactor)
  end

  let(:close_nps_cycle_if_max_score_exceeds_interactor) do
    instance_double(Customer::Constituents::Surveys::Interactors::CloseNPSCycleIfMaxScoreExceeds)
  end

  let(:interaction_repository) do
    instance_double(Customer::Constituents::Surveys::Repositories::NPSInteractionRepository)
  end

  describe "#call" do
    let(:customer_id) { 1 }
    let(:params) { { score: 10 } }

    context "when valid" do
      it "calls repository and close_nps_cycle_if_max_score_exceeds interactor" do
        expect(interaction_repository).to receive(:create!).with(customer_id, params)
        expect(close_nps_cycle_if_max_score_exceeds_interactor).to receive(:call)

        result = interactor.call(customer_id: customer_id, attributes: params)
        expect(result.ok?).to be true
      end
    end

    context "when something goes wrong" do
      before do
        allow(interaction_repository).to receive(:create!).and_raise(StandardError, "Whoops!")
      end

      it "catches the error and returns it" do
        result = interactor.call(customer_id: customer_id, attributes: params)
        expect(result.ok?).to be false
        result.on_failure { |error| expect(error.message).to eq("Whoops!") }
      end
    end
  end
end
