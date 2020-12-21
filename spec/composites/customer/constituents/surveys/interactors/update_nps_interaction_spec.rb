# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/surveys/repositories/nps_interaction_repository"
require "composites/customer/constituents/surveys/interactors/update_nps_interaction"

RSpec.describe Customer::Constituents::Surveys::Interactors::UpdateNPSInteraction do
  let(:interactor) { described_class.new(interactions_repo: double_nps_repo) }

  let(:double_nps_repo) do
    instance_double(Customer::Constituents::Surveys::Repositories::NPSInteractionRepository)
  end

  describe "#call" do
    let(:customer_id) { 1 }
    let(:interaction_id) { 1 }
    let(:comment) { "Super cool app" }

    context "when valid" do
      it "calls nps_repository" do
        expect(double_nps_repo).to receive(:update_comment!).with(customer_id, interaction_id, comment)

        result = interactor.call(customer_id: customer_id, id: interaction_id, comment: comment)
        expect(result.ok?).to be true
      end
    end

    context "when comment param is nil" do
      let(:comment) { nil }

      it "does not calls nps_repository" do
        expect(double_nps_repo).not_to receive(:update_comment!).with(customer_id, interaction_id, comment)

        result = interactor.call(customer_id: customer_id, id: interaction_id, comment: comment)
        expect(result.ok?).to be false
        result.on_success { |value| expect(value).to be_kind_of Interactors::Errors::ValidationError }
      end
    end

    context "when something goes wrong" do
      before do
        allow(double_nps_repo).to receive(:update_comment!).and_raise(StandardError, "Whoops!")
      end

      it "catches the error and returns it" do
        result = interactor.call(customer_id: customer_id, id: interaction_id, comment: comment)
        expect(result.ok?).to be false
        result.on_failure { |error| expect(error.message).to eq("Whoops!") }
      end
    end
  end
end
