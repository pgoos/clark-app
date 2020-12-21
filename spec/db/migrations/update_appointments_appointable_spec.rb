# frozen_string_literal: true

require "rails_helper"

require "migration_data/testing"
require_migration "update_appointments_appointable"

RSpec.describe UpdateAppointmentsAppointable, :integration do
  let(:mandate1)       { create(:mandate) }
  let(:mandate2)       { create(:mandate) }
  let(:mandate3)       { create(:mandate) }

  let!(:cockpit1)       { create(:retirement_cockpit, mandate: mandate1) }
  let!(:cockpit2)       { create(:retirement_cockpit, mandate: mandate2) }
  let!(:cockpit3)       { create(:retirement_cockpit, mandate: mandate3) }

  let(:category)      { create(:category, ident: "vorsorgeprivat") }
  let(:questionnaire) { create(:questionnaire, category: category) }
  let(:response)      { create(:questionnaire_response, :retirementcheck, questionnaire: questionnaire) }
  let(:advice)        { create(:advice) }

  describe "#data" do
    let!(:retirement_appointment1) { create(:appointment, appointable: cockpit1) }
    let!(:retirement_opportunity1) { create(:opportunity, source: retirement_appointment1, mandate: mandate1) }
    let!(:retirement_appointment2) { create(:appointment, appointable: cockpit2) }
    let!(:retirement_opportunity2) { create(:opportunity, source: retirement_appointment2, mandate: mandate2) }
    let!(:retirement_appointment3) { create(:appointment, appointable: cockpit3) }
    let!(:retirement_opportunity3) { create(:opportunity, source: retirement_appointment3, mandate: mandate3) }

    let!(:appointment1) { create(:appointment, appointable: advice) }
    let!(:opportunity1) { create(:opportunity, source: response, mandate: mandate1) }
    let!(:appointment2) { create(:appointment, appointable: advice) }
    let!(:opportunity2) { create(:opportunity, source: response, mandate: mandate2) }
    let!(:appointment3) { create(:appointment, appointable: advice) }
    let!(:opportunity3) { create(:opportunity, source: response, mandate: mandate3) }

    it "updates only retirement appointments appointable" do
      described_class.new.data

      expect(retirement_appointment1.reload.appointable).to eq retirement_opportunity1
      expect(retirement_appointment2.reload.appointable).to eq retirement_opportunity2
      expect(retirement_appointment3.reload.appointable).to eq retirement_opportunity3

      expect(appointment1.reload.appointable).to eq advice
      expect(appointment2.reload.appointable).to eq advice
      expect(appointment3.reload.appointable).to eq advice
    end
  end

  describe "#rollback" do
    let!(:retirement_appointment1) { create(:appointment) }
    let!(:retirement_opportunity1) { create(:opportunity, source: retirement_appointment1, mandate: mandate1) }
    let!(:retirement_appointment2) { create(:appointment) }
    let!(:retirement_opportunity2) { create(:opportunity, source: retirement_appointment2, mandate: mandate2) }
    let!(:retirement_appointment3) { create(:appointment) }
    let!(:retirement_opportunity3) { create(:opportunity, source: retirement_appointment3, mandate: mandate3) }

    let!(:appointment1) { create(:appointment) }
    let!(:opportunity1) { create(:opportunity, source: response) }
    let!(:appointment2) { create(:appointment) }
    let!(:opportunity2) { create(:opportunity, source: response) }
    let!(:appointment3) { create(:appointment) }
    let!(:opportunity3) { create(:opportunity, source: response) }

    before do
      retirement_appointment1.update!(appointable: retirement_opportunity1)
      retirement_appointment2.update!(appointable: retirement_opportunity2)
      retirement_appointment3.update!(appointable: retirement_opportunity3)

      appointment1.update!(appointable: opportunity1)
      appointment2.update!(appointable: opportunity2)
      appointment3.update!(appointable: opportunity3)
    end

    it "rollbacks only retirement appointments appointable" do
      described_class.new.rollback

      expect(retirement_appointment1.reload.appointable).to eq cockpit1
      expect(retirement_appointment2.reload.appointable).to eq cockpit2
      expect(retirement_appointment3.reload.appointable).to eq cockpit3

      expect(appointment1.reload.appointable).to eq opportunity1
      expect(appointment2.reload.appointable).to eq opportunity2
      expect(appointment3.reload.appointable).to eq opportunity3
    end
  end
end
