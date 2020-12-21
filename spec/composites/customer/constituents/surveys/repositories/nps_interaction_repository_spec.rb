# frozen_string_literal: true

require "rails_helper"

require "composites/customer/constituents/surveys/repositories/nps_interaction_repository"

RSpec.describe Customer::Constituents::Surveys::Repositories::NPSInteractionRepository, :integration do
  let(:mandate) { create(:mandate) }
  let(:repository) { described_class.new }

  describe "#create!" do
    shared_examples "a valid nps interaction" do
      context "when correct params are passed in" do
        let(:params) { { "score": 10, "comment": "Noice" } }

        it "creates nps interaction and returns object" do
          expect {
            result = repository.create!(mandate.id, params)

            expect(result).to be_a(Customer::Constituents::Surveys::Entities::NPSInteraction)

            interaction = NPSInteraction.find(result.id)
            nps = interaction.nps
            expect(nps.score).to be(10)
            expect(nps.comment).to eq("Noice")
          }.to change(NPS, :count).by(1).and change(NPSInteraction, :count).by(1)
        end
      end

      context "when incorrect params are passed in" do
        let(:invalid_params) { { "score": 11, "comment": "Noice" } }

        it "rescue ActiveRecord error and throw Repository errors" do
          expect {
            repository.create!(mandate.id, invalid_params)
          }.to raise_error(Utils::Repository::Errors::ValidationError)
        end
      end
    end

    context "when NPS cycle is OPEN" do
      before { create(:nps_cycle, :open, end_at: Time.zone.now + 7.days) }

      it_behaves_like "a valid nps interaction"
    end

    context "when NPS cycle is CLOSING" do
      before { create(:nps_cycle, :closing, end_at: Time.zone.now + 7.days) }

      it_behaves_like "a valid nps interaction"
    end

    context "when NPS Cycle is CLOSED" do
      let(:params) { { "score": 10, "comment": "Noice" } }

      before { create(:nps_cycle, :closed, end_at: Time.zone.now + 7.days) }

      it "raises an error" do
        expect {
          repository.create!(mandate.id, params)
        }.to raise_error(Utils::Repository::Errors::Error)
      end
    end
  end

  describe "#create_refused!" do
    shared_examples "a valid refused nps interaction" do
      it "creates nps interaction without a NPS" do
        nps_count = NPS.count
        interaction_count = NPSInteraction.count

        result = repository.create_refused!(mandate.id)

        expect(result).to be_a(Customer::Constituents::Surveys::Entities::NPSInteraction)
        expect(NPS.count).to be(nps_count)
        expect(NPSInteraction.count).to be(interaction_count + 1)
      end
    end

    context "when NPS cycle is OPEN" do
      before { create(:nps_cycle, :open, end_at: Time.zone.now + 7.days) }

      it_behaves_like "a valid refused nps interaction"
    end

    context "when NPS cycle is CLOSING" do
      before { create(:nps_cycle, :closing, end_at: Time.zone.now + 7.days) }

      it_behaves_like "a valid refused nps interaction"
    end

    context "when NPS Cycle is CLOSED" do
      before { create(:nps_cycle, :closed, end_at: Time.zone.now + 7.days) }

      it "raises an error" do
        expect {
          repository.create_refused!(mandate.id)
        }.to raise_error(Utils::Repository::Errors::Error)
      end
    end

    describe "#update_comment!" do
      let(:interaction) { create(:nps_interaction) }

      it "updates nps comment" do
        comment = "Real good"
        result = repository.update_comment!(interaction.mandate_id, interaction.id, comment)
        interaction.reload

        expect(result.id).to eq(interaction.id)
        expect(interaction.nps.comment).to eq(comment)
      end
    end
  end
end
