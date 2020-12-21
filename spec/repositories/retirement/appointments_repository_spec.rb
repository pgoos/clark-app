# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::AppointmentsRepository, :integration do
  subject { described_class.new }

  let(:mandate)       { create(:mandate) }
  let(:cockpit)       { create(:retirement_cockpit, mandate: mandate) }
  let(:category)      { create(:category, ident: "vorsorgeprivat") }
  let(:questionnaire) { create(:questionnaire, category: category) }
  let(:response)      { create(:questionnaire_response, :retirementcheck, questionnaire: questionnaire) }
  let(:opportunity1)   { create(:opportunity) }
  let(:opportunity2)   { create(:opportunity, source: response) }

  describe ".all" do
    context "when retirement cockpit is not available" do
      let!(:old_appointments) { create_list(:appointment, 2) }

      it "returns blank collection" do
        appointments = subject.all(mandate)

        expect(appointments).to be_empty
      end
    end

    context "when retirement cockpit is available" do
      let!(:appointment1) do
        create :appointment,
               mandate: mandate,
               appointable_type: opportunity1.class.name,
               appointable_id: opportunity1.id,
               created_at: 3.days.ago,
               method_of_contact: method_of_contact
      end

      let!(:appointment2) do
        create :appointment,
               mandate: mandate,
               appointable_type: opportunity2.class.name,
               appointable_id: opportunity2.id,
               created_at: 1.day.ago
      end

      let!(:appointments) { create_list :appointment, 2, mandate: mandate }

      before do
        opportunity1.update!(source: appointment1)
      end

      context "when method_of_contact equals 'phone'" do
        let(:method_of_contact) { "phone" }

        it { expect(subject.all(mandate).count).to eq(2) }

        it "returns retirement-related appointment" do
          expect(subject.all(mandate)).to eq([appointment2, appointment1])
        end
      end

      context "when method_of_contact equals 'email'" do
        let(:method_of_contact) { "email" }

        it { expect(subject.all(mandate).count).to eq(1) }

        it "returns retirement-related appointment" do
          expect(subject.all(mandate)).to eq([appointment2])
        end
      end
    end
  end
end
