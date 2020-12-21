# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/surveys/repositories/nps_cycle_repository"

RSpec.describe Customer::Constituents::Surveys::Repositories::NPSCycleRepository, :integration do
  let(:fake_cycle_id) { "9f3bf312-43bf-4ab3-bcad-9ac2b751fafb" }
  let(:nps_cycle)     { create(:nps_cycle, :open, end_at: Time.zone.now + 7.days, maximum_score: 100) }
  let(:repository)    { described_class.new }

  describe "#find_by" do
    context "when cycle with provided id exists" do
      it "returns cycle entity" do
        result = repository.find_by(cycle_id: nps_cycle.id)
        expect(result).to be_a(Customer::Constituents::Surveys::Entities::NPSCycle)
        expect(result.end_at.inspect).to eq(nps_cycle.end_at.inspect)
        expect(result.maximum_score).to eq(nps_cycle.maximum_score)
        expect(result.state).to eq(nps_cycle.state)
      end
    end

    context "when cycle with provided id doesn't exist" do
      it "returns nil" do
        result = repository.find_by(cycle_id: fake_cycle_id)
        expect(result).to be_nil
      end
    end
  end

  describe "#open_cycle" do
    context "when there is an open cycle" do
      let!(:nps_cycle_open) { create(:nps_cycle, :open, end_at: Time.zone.now + 7.days, maximum_score: 100) }

      it "returns this cycle" do
        result = repository.open_cycle
        expect(result).to be_a(Customer::Constituents::Surveys::Entities::NPSCycle)
        expect(result.id).to eq(nps_cycle_open.id)
      end
    end

    context "when there are no open cycles" do
      let!(:nps_cycle_closing) { create(:nps_cycle, :closing) }
      let!(:nps_cycle_closed)  { create(:nps_cycle, :closed)  }

      it "returns nil" do
        result = repository.open_cycle
        expect(result).to be_nil
      end
    end
  end

  describe "#amount_of_rated_nps_interactions" do
    context "when nps interactions exist" do
      let(:nps_1) { create(:nps, score: 5) }
      let(:nps_2) { create(:nps, score: 10) }
      let!(:nps_interaction_1) { create(:nps_interaction, nps_cycle: nps_cycle, nps: nps_1) }
      let!(:nps_interaction_2) { create(:nps_interaction, nps_cycle: nps_cycle, nps: nps_2) }
      let!(:nps_interaction_3) { create(:nps_interaction, nps_cycle: nps_cycle, nps: nil)   }

      it "returns valid nps amount" do
        result = repository.amount_of_rated_nps_interactions(nps_cycle.id)
        expect(result).to eq(2)
      end
    end

    context "when nps interactions don't exists" do
      it "returns zero" do
        result = repository.amount_of_rated_nps_interactions(nps_cycle.id)
        expect(result).to eq(0)
      end
    end

    context "when Cycle with provided ID doesn't exist" do
      it "returns zero" do
        result = repository.amount_of_rated_nps_interactions(fake_cycle_id)
        expect(result).to eq(0)
      end
    end
  end

  describe "#update_cycle_state!" do
    context "when params are valid" do
      shared_examples "a valid cycle update operation" do
        it "updates cycle state" do
          repository.update_cycle_state!(nps_cycle.id, target_state)
          nps_cycle.reload
          expect(nps_cycle.state).to eq(target_state)
        end
      end

      context "when target state is CLOSING" do
        let(:target_state) { "CLOSING" }

        it_behaves_like "a valid cycle update operation"
      end

      context "when target state is CLOSED" do
        let(:target_state) { "CLOSED" }

        it_behaves_like "a valid cycle update operation"
      end
    end

    context "when cycle with provided id doesn't exist" do
      it "raises NotFoundError" do
        expect {
          repository.update_cycle_state!(fake_cycle_id, "CLOSED")
        }.to raise_error(Utils::Repository::Errors::NotFoundError)
      end
    end
  end

  describe "#current_cycle" do
    context "when NPS cycle is OPEN" do
      it "returns it" do
        cycle = create(:nps_cycle, :open, maximum_score: 300, end_at: Time.current + 7.days)

        entity = repository.current_cycle
        expect(entity.id).to eq(cycle.id)
        expect(entity.state).to eq(cycle.state)
      end
    end

    context "when NPS cycle is CLOSING" do
      it "returns it" do
        cycle = create(:nps_cycle, :closing, maximum_score: 300, end_at: Time.current + 7.days)

        entity = repository.current_cycle
        expect(entity.id).to eq(cycle.id)
        expect(entity.state).to eq(cycle.state)
      end
    end
  end

  describe "#open_new_cycle!" do
    context "when there is no open cycle" do
      it "creates a NPS Cycle with OPEN state" do
        expect {
          repository.open_new_cycle!(maximum_score: 300, end_at: Time.current + 7.days)
        }.to change(NPSCycle, :count).by(1)
      end
    end

    context "when there is an open cycle" do
      before { create(:nps_cycle, :open, end_at: Time.current + 7.days) }

      it "raises an error" do
        expect {
          repository.open_new_cycle!(maximum_score: 300, end_at: Time.current + 7.days)
        }.to raise_error("There is an open cycle already")
      end
    end
  end
end
