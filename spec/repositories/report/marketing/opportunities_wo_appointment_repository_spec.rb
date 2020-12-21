# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Marketing::OpportunitiesWoAppointmentRepository, :integration do
  subject { described_class.new }

  let!(:mandate) { create(:mandate, :accepted, :with_phone, :with_user) }
  let!(:category) { create(:high_margin_category, margin_level: :high) }
  let(:opportunity_created_at) { Time.parse("#{DateTime.yesterday} 10:00am") }
  let!(:opportunity) do
    create(
      :opportunity,
      mandate: mandate,
      category: category,
      created_at: opportunity_created_at
    )
  end

  describe "#all" do
    it "returns the correct result" do
      expect(subject.all.size).to eq(1)
      expect(subject.all.first["mandate_id"]).to eq(mandate.id)
    end

    context "opportunity created few days ago" do
      let(:opportunity_created_at) { Time.parse("#{4.days.ago} 10:00am") }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "not high margin category" do
      let!(:category) { create(:category) }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "when corresponding mandate is rejected for opportunity" do
      it "should not be included" do
        rejected_mandate = create(:mandate, :rejected)
        create(:opportunity, mandate: rejected_mandate)

        expect(subject.all.map { |a| a["mandate_id"] }).not_to include(rejected_mandate.id)
      end
    end
  end
end
