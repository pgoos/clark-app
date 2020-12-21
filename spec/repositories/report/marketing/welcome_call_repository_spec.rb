# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Marketing::WelcomeCallRepository, :integration do
  subject { described_class.new }

  let(:mandate_created_at) { Date.today.at_beginning_of_week - 2.day }

  let!(:mandate) do
    create(
      :mandate, :accepted, :owned_by_clark, :with_user, :with_phone,
      gender: :male, birthdate: 27.years.ago, created_at: mandate_created_at
    )
  end

  let(:questionnaire) { create(:bedarfscheck_questionnaire) }
  let(:q_response) { create(:questionnaire_response, mandate: mandate, questionnaire: questionnaire, state: qr_state) }

  describe "#all" do
    context "mandate created this week" do
      let(:mandate_created_at) { Time.current }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "mandate created 2 weeks ago" do
      let(:mandate_created_at) { Date.today.at_beginning_of_week - 10.day }

      it "should not be included" do
        expect(subject.all.size).to eq(0)
      end
    end

    context "mandate created last week" do
      it "returns the correct result" do
        expect(subject.all.size).to eq(1)
        expect(subject.all.first["id"]).to eq(mandate.id)
        expect(subject.all.first.keys)
          .to match_array(%w[
                            id first_name last_name mandate_created_date
                            phone_number age gender grossincome did_demand_check
                          ])
      end

      context "has high margin opportunity" do
        before do
          create(
            :opportunity,
            mandate: mandate,
            category: create(:high_margin_category, margin_level: :high),
            source_type: "Questionnaire::Response"
          )
        end

        it "should not be included" do
          expect(subject.all.size).to eq(0)
        end
      end

      context "has reached phone call" do
        before do
          create(:welcome_call, :successful, mandate: mandate)
        end

        it "should not be included" do
          expect(subject.all.size).to eq(0)
        end
      end

      context "mandate has completed and analyzed demand check" do
        let(:qr_state) { :analyzed }

        before { q_response }

        it "demand_check column is true" do
          expect(subject.all.first["did_demand_check"]).to eq("yes")
        end
      end

      context "mandate has unfinished demand check" do
        let(:qr_state) { :in_progress }

        before { q_response }

        it "demand_check column is true" do
          expect(subject.all.first["did_demand_check"]).to eq("no")
        end
      end

      context "mandate has multiple demand check or other low margin questionnaire response" do
        let(:qr_state) { :analyzed }

        before do
          create(:questionnaire_response, mandate: mandate, questionnaire: questionnaire, state: :in_progress)
          q_response
          create(:questionnaire_response, mandate: mandate, questionnaire: questionnaire, state: :in_progress)
          q = create(:questionnaire, category: create(:category, :low_margin))
          create(:questionnaire_response, mandate: mandate, questionnaire: q)
        end

        it "it should be only included once" do
          expect(subject.all.first["did_demand_check"]).to eq("yes")
          expect(subject.all.count).to eq(1)
        end
      end

      context "mandate did not participated in demand check" do
        it "demand_check column is false" do
          expect(subject.all.first["did_demand_check"]).to eq("no")
        end
      end
    end
  end
end
