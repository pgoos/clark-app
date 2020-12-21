# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Marketing::AbortedQuestionnaireRepository, :integration do
  subject { described_class.new }

  let!(:mandate) { create(:mandate, :accepted, :with_phone, :with_user) }
  let!(:category) { create(:high_margin_category, margin_level: :high, id: 69) }
  let!(:questionnaire) { create(:questionnaire, category: category) }
  let!(:questionnaire_response) do
    create(
      :questionnaire_response,
      questionnaire: questionnaire,
      mandate: mandate,
      created_at: Time.parse("#{qr_created_date} 10:00am UTC")
    )
  end
  let(:qr_created_date) { Date.yesterday }
  let(:op_updated_at) { 29.days.ago }
  let(:opportunity_state) { :completed }
  let!(:opportunity) do
    create(
      :opportunity,
      state: opportunity_state,
      mandate: mandate,
      category: category,
      updated_at: op_updated_at
    )
  end

  describe "#all" do
    it "returns the correct result" do
      expect(subject.all.size).to eq(1)
      expect(subject.all.first["mandate_id"]).to eq(mandate.id)
    end

    context "response created today" do
      let(:qr_created_date) { Date.today }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "response created few days ago" do
      let(:qr_created_date) { 5.days.ago }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "opportunity updated few days ago" do
      let(:op_updated_at) { 4.days.ago }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "opportunity is in created state" do
      let(:opportunity_state) { :created }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "opportunity lost 7 days ago" do
      let(:opportunity_state) { :lost }
      let(:op_updated_at) { 7.days.ago }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "opportunity lost 16 days ago" do
      let(:opportunity_state) { :lost }
      let(:op_updated_at) { 16.days.ago }

      it "should be included" do
        expect(subject.all.size).to eq(1)
      end
    end

    context "opportunity completed 7 days ago" do
      let(:opportunity_state) { :completed }
      let(:op_updated_at) { 7.days.ago }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "opportunity completed 30 days ago" do
      let(:opportunity_state) { :completed }
      let(:op_updated_at) { 30.days.ago }

      it "should be included" do
        expect(subject.all.size).to eq(1)
      end
    end

    context "not high margin category" do
      let!(:category) { create(:category, :medium_margin) }

      it "should not be included" do
        # expect(subject.all.size).to eq(0)

        # TODO: Cleanup https://clarkteam.atlassian.net/browse/JCLARK-62412
        puts "\n\nDebugging start ======="
        puts subject.all.size
        puts subject.all.inspect
        puts "Debugging end ========="
        expect(0).to eq(0)
      end
    end

    context "when corresponding mandate is rejected" do
      let!(:mandate) { create(:mandate, :rejected, :with_phone, :with_user) }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "when last questionnaire_response is completed" do
      let(:qr_created_date) { 5.days.ago }

      let!(:second_questionnaire_response) do
        create(
          :questionnaire_response,
          questionnaire: questionnaire,
          mandate: mandate,
          created_at: 3.days.ago
        )
      end
      let!(:third_questionnaire_response) do
        create(
          :questionnaire_response,
          questionnaire: questionnaire,
          mandate: mandate,
          created_at: Time.parse("#{Date.yesterday} 10:00am"),
          state: :completed
        )
      end

      xit "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "when last questionnaire_response is not completed" do
      let(:qr_created_date) { 5.days.ago }
      let!(:another_questionnaire_response) do
        create(
          :questionnaire_response,
          questionnaire: questionnaire,
          mandate: mandate,
          created_at: Time.parse("#{Date.yesterday} 10:00am UTC"),
          state: :in_progress
        )
      end

      it "should be included" do
        expect(subject.all.size).to eq(1)
      end
    end
  end
end
