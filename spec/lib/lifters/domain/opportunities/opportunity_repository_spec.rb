# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Opportunities::OpportunityRepository do
  let(:opportunity) { create(:opportunity) }
  let(:subject) { described_class }

  describe "#open_opportunities" do
    context "when an opportunity is in state offer_phase" do
      before do
        opportunity.state = :offer_phase
        opportunity.save!
      end

      context "when an opportunity is 30 days old" do
        before do
          opportunity.created_at = 31.days.ago
          opportunity.save!
        end

        it "it returns the opportunity with the time threshold" do
          opportunities = subject.open_opportunities
          expect(opportunities.first).to eq(opportunity)
        end
      end

      context "when an opportunity is less than threshold time" do
        before do
          opportunity.created_at = 29.days.ago
          opportunity.save!
        end

        it "does not return the opportunity" do
          opportunities = subject.open_opportunities
          expect(opportunities).to be_empty
        end
      end
    end

    context "when opportunity is in state lost or completed" do
      before do
        opportunity.state = :completed
        opportunity.created_at = 31.days.ago
        opportunity.save!
      end

      it "it does not return the opportunity" do
        opportunities = subject.open_opportunities
        expect(opportunities).to be_empty
      end
    end
  end

  describe "#mark_opportunity_as_lost" do
    context "when the opportunity is in state offer" do
      before do
        opportunity.state = "offer_phase"
        opportunity.save!
      end

      it "updates the state to lost" do
        expect(described_class.mark_opportunity_as_lost(opportunity)).to be_truthy
        expect(opportunity.reload.state).to eq("lost")
      end
    end

    context "when the opportunity is not in state offer" do
      before do
        opportunity.state = "created"
        opportunity.save!
      end

      context "when creation date is greater or equal than the threshold creation date" do
        before do
          opportunity.created_at = 90.days.ago
        end

        it "updates the state to lost" do
          expect(described_class.mark_opportunity_as_lost(opportunity)).to be_truthy
          expect(opportunity.reload.state).to eq("lost")
        end
      end

      context "when creation date is less than the threshold creation date" do
        before do
          opportunity.created_at = 89.days.ago
        end

        it "does not update the state to lost" do
          expect(described_class.mark_opportunity_as_lost(opportunity)).to be_falsy
          expect(opportunity.reload.state).not_to eq("lost")
        end
      end
    end
  end

  describe "#where", :integration do
    let(:admin) { create(:admin) }
    let(:mandate) { create(:mandate) }
    let(:low_margin_category) { create(:category, :low_margin) }
    let(:medium_margin_category) { create(:category, :medium_margin) }
    let(:high_margin_category) { create(:category, :high_margin) }
    let(:scope) { Opportunity.where(admin: nil, state: "created") }

    let!(:opportunities) do
      [
        create(:opportunity, :created, :unassigned, category: low_margin_category),
        create(:opportunity, :created, :unassigned, category: medium_margin_category),
        create(:opportunity, :created, :unassigned, category: high_margin_category),
        create(:opportunity, :created, :unassigned, category: low_margin_category),
        create(:opportunity, :created, :unassigned, category: medium_margin_category),
        create(:opportunity, :created, :unassigned, category: high_margin_category),
        create(:opportunity, :created, admin: admin, category: low_margin_category),
        create(:opportunity, :created, admin: admin, category: medium_margin_category),
        create(:opportunity, :created, admin: admin, category: high_margin_category),
        create(:opportunity, :initiation_phase, :unassigned, category: low_margin_category),
        create(:opportunity, :initiation_phase, admin: admin, category: low_margin_category)
      ]
    end

    let!(:appointments) do
      [
        create(:appointment, mandate: mandate, appointable: opportunities[3]),
        create(:appointment, mandate: mandate, appointable: opportunities[4]),
        create(:appointment, mandate: mandate, appointable: opportunities[5])
      ]
    end

    it "passes scenario" do
      expect(described_class.where.size).to eq 11
      expect(described_class.where(scope: scope).size).to eq 6
      expect(described_class.where(scope: scope, margin_level: "low").size).to eq 2
      expect(described_class.where(scope: scope, margin_level: "medium").size).to eq 2
      expect(described_class.where(scope: scope, margin_level: "high").size).to eq 2
      expect(described_class.where(scope: scope, margin_level: "all").size).to eq 6
      expect(described_class.where(scope: scope, appointment_scheduled: "yes").size).to eq 3
      expect(described_class.where(scope: scope, appointment_scheduled: "no").size).to eq 3
      expect(described_class.where(scope: scope, appointment_scheduled: "all").size).to eq 6
      expect(described_class.where(scope: scope, margin_level: "low", appointment_scheduled: "yes").size).to eq 1
      expect(described_class.where(scope: scope, margin_level: "high", appointment_scheduled: "yes").size).to eq 1
      expect(described_class.where(scope: scope, category_idents: [low_margin_category.ident]).size).to eq 2
      expect(
        described_class
          .where(scope: scope, category_idents: [low_margin_category.ident, high_margin_category.ident])
          .size
      ).to eq 4
    end
  end

  describe "#unassigned", :integration do
    let(:admin) { create(:admin) }

    let!(:unassigned1) { create(:opportunity, :created, :unassigned) }
    let!(:unassigned2) { create(:opportunity, :created, :unassigned) }
    let!(:unassigned3) { create(:opportunity, :created, :unassigned) }
    let!(:assigned1) { create(:opportunity, :created, admin: admin) }
    let!(:assigned2) { create(:opportunity, :created, admin: admin) }
    let!(:assigned3) { create(:opportunity, :created, admin: admin) }

    it "returns only anassigned opportunities" do
      expect(described_class.unassigned({})).to match_array([unassigned1, unassigned2, unassigned3])
    end

    it "sorted properly (the latest on top)" do
      expect(described_class.unassigned({}).map(&:id)).to eq([unassigned3.id, unassigned2.id, unassigned1.id])
    end
  end
end
