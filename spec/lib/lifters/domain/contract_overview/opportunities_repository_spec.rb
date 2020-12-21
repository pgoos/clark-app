# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::OpportunitiesRepository do
  subject(:repo) { described_class.new }

  let(:mandate) { create :mandate, opportunities: [opportunity] }
  let(:category) { create(:category) }
  let(:offer_1) { create(:offer) }
  let(:offer_2) { create(:offer) }
  let(:offer_ids) { [offer_1.id] }

  context "when offer is in argument offer_ids list" do
    let(:opportunity) { create :opportunity, offer: offer_1, category: category }

    it "includes an opportunity" do
      expect(repo.all(mandate, offer_ids)).to include opportunity
    end
  end

  context "when offer is not in argument offer_ids list" do
    let(:opportunity) { create :opportunity, offer: offer_2 }

    it "does not include the opportunity" do
      expect(repo.all(mandate, offer_ids)).not_to include opportunity
    end
  end

  context "when opportunity does not have offer" do
    context "when opportunity is in 'created' state" do
      let(:opportunity) { create :opportunity, :created }

      it "includes an opportunity" do
        expect(repo.all(mandate, offer_ids)).to include opportunity
      end
    end

    context "when opportunity is in 'initiation_phase' state" do
      let(:opportunity) { create :opportunity, :initiation_phase }

      it "includes an opportunity" do
        expect(repo.all(mandate, offer_ids)).to include opportunity
      end
    end

    context "when opportunity is in 'offer_phase' state" do
      let(:opportunity) { create :opportunity, :offer_phase }

      it "includes an opportunity" do
        expect(repo.all(mandate, offer_ids)).to include opportunity
      end
    end

    context "when opportunity is in 'completed' state" do
      let(:opportunity) { create :opportunity, :completed }

      it "includes an opportunity" do
        expect(repo.all(mandate, offer_ids)).not_to include opportunity
      end
    end

    context "when opportunity is in 'lost' state" do
      let(:opportunity) { create :opportunity, :lost }

      it "includes an opportunity" do
        expect(repo.all(mandate, offer_ids)).not_to include opportunity
      end
    end

    context "when opportunity is of vertical mortgage" do
      let(:vertical) { create(:vertical, ident: "IMMO") }
      let(:mortgage_category) { create(:category, vertical: vertical, name: "Mortgage") }
      let(:opportunity) do
        create :opportunity, :initiation_phase, category: mortgage_category
      end

      it "does not include opportunity" do
        expect(repo.all(mandate, offer_ids)).not_to include opportunity
      end
    end
  end
end
