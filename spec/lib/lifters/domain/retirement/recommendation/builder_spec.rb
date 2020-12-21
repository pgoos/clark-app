# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Recommendation::Builder do
  subject { described_class.new(mandate) }

  let(:mandate) { create(:mandate) }
  let(:idents) do
    %w[1ded8a0f vorsorgeprivat 84a5fba0]
  end
  let(:occupation) { "Angestellter" }
  let(:rules) do
    instance_double Domain::Retirement::Recommendation::CategoryRulesLoader, call: idents
  end
  let(:situation) do
    instance_double Domain::Situations::RetirementSituation, occupation: occupation
  end

  before do
    @company_category = create(:category, ident: "1ded8a0f")
    @private_category = create(:category, ident: "vorsorgeprivat")
    @statutory_category = create(:category, ident: "84a5fba0")

    allow(Domain::Situations::RetirementSituation).to receive(:new).with(mandate) { situation }
    allow(Domain::Retirement::Recommendation::CategoryRulesLoader).to receive(:new).with(situation) { rules }
  end

  describe "#call" do
    context "when no recommendations created yet" do
      it "creates a Private Altervorsoge recommendation" do
        expect(mandate.recommendations.count).to be_zero

        expect { subject.call }.to change(Recommendation, :count).by(3)
      end

      it "set all recommendations as important" do
        subject.call

        mandate.recommendations.each do |recommendation|
          expect(recommendation.level).to eq("very_important")
        end
      end
    end

    context "when mandate already have recommendation" do
      before do
        @recommendation1 = create(:recommendation, mandate: mandate, category: @private_category)
        @recommendation2 = create(:recommendation, mandate: mandate, category: @company_category)
        @recommendation3 = create(:recommendation, mandate: mandate, category: @statutory_category)
      end

      it "deletes current recommendations and builds new ones" do
        subject.call

        expect { @recommendation1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { @recommendation2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { @recommendation3.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect(mandate.recommendations.count).to eq(3)
      end
    end
  end
end
