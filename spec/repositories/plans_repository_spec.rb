# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlansRepository, :integration do
  context "#find" do
    let(:plan) { create(:plan) }

    it "returns an instance of Structs::Plan" do
      struct = described_class.find(plan.id)

      expect(struct).to be_kind_of(Structs::Plan)
    end

    it "returns correct values" do
      struct = described_class.find(plan.id)

      expect(struct.id).to eq(plan.id)
    end
  end

  context "#all_by" do
    let(:idents) { %w[ident-1 ident-2] }

    before do
      idents.each { |ident| create(:plan, ident: ident) }
    end

    it "retrieves all plans with matching idents" do
      plans = described_class.all_by(ident: idents)

      expect(plans.length).to be(2)
    end

    context "when there is a ident missing" do
      it "retrieves only plans with matching idents" do
        idents.push "no-existing-ident"

        plans = described_class.all_by(ident: idents)

        expect(plans.length).to be(2)
      end
    end
  end
end
