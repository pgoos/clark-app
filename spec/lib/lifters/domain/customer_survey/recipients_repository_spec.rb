# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::CustomerSurvey::RecipientsRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#accepted_at" do
    let(:range) { 30.days.ago.beginning_of_day..30.days.ago.end_of_day }

    before do
      unless DocumentType.satisfaction_email
        create(:document_type,
               template: "customer_survey_mailer/satisfaction")
      end
    end

    it "returns enumerator" do
      expect(repo.accepted_at(range)).to be_kind_of Enumerator
    end

    context "when mandates is not accepted" do
      let(:mandate) { create :mandate, :created, :owned_by_clark }

      it do
        expect(repo.accepted_at(range).to_a).not_to include mandate
      end
    end

    context "when mandates is approved" do
      let(:mandate) { create :mandate, :accepted, :owned_by_clark }

      context "when mandates was approved within given range" do
        before do
          create(:business_event, action: :accept, entity: mandate, created_at: 30.days.ago)
        end

        it do
          expect(repo.accepted_at(range).to_a).to include mandate
        end

        context "when mandates is not owned by Clark" do
          let(:mandate) { create :mandate, :accepted, :owned_by_n26 }

          it do
            expect(repo.accepted_at(range).to_a).not_to include mandate
          end
        end

        context "when mandates has already received satisfaction email" do
          before do
            create(:document, document_type: DocumentType.satisfaction_email, documentable: mandate)
          end

          it do
            expect(repo.accepted_at(range).to_a).not_to include mandate
          end
        end

        context "when there are two business events about mandate approval" do
          before do
            create(:business_event, entity: mandate, action: :accept, created_at: 30.days.ago)
          end

          it "includes only one instance of mandate" do
            expect(repo.accepted_at(range).to_a).to match_array [mandate]
          end
        end
      end

      context "when mandates was approved out of given range" do
        it do
          create(:business_event, entity: mandate, action: :accept, created_at: 29.days.ago)
          expect(repo.accepted_at(range).to_a).not_to include mandate
        end

        it do
          create(:business_event, entity: mandate, action: :accept, created_at: 31.days.ago)
          expect(repo.accepted_at(range).to_a).not_to include mandate
        end
      end
    end
  end
end
