# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MandateFunnel::TermsAcceptance do
  subject { described_class.new(mandate) }

  let(:mandate) { create(:mandate) }
  let!(:user) { create(:user, mandate: mandate) }

  describe "#perform" do
    context "When the mandate does not have a tos_accepted" do
      before do
        mandate.profiling
        mandate.targeting
        mandate.tos_accepted = nil
        mandate.save!
      end

      it "updates the timestamp to the current time" do
        expect(subject.perform).to be_truthy
        expect(mandate.tos_accepted).to be_truthy
        expect(mandate.confirmed).to be_truthy
        expect(mandate.signatures.size).to eq 1
        expect(mandate.wizard_steps).to include("confirming")
      end
    end

    context "When the mandate already has a tos_accepted timestamp" do
      let(:tos_accepted_time) { Time.zone.now }
      before do
        mandate.tos_accepted = tos_accepted_time
        mandate.save!
      end

      it "updates the timestamp to the current time" do
        expect(subject.perform).to be_truthy
        expect(mandate.tos_accepted_at).not_to eq(tos_accepted_time)

        expect(mandate.tos_accepted).to be_truthy
      end
    end
  end
end
