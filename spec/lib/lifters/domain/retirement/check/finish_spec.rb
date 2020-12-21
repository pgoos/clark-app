# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Check::Finish do
  describe ".call" do
    let(:mandate) { create(:mandate) }
    let(:questionnaire_response) { create(:questionnaire_response, state: :in_progress) }
    let(:initial_income) { instance_double(Domain::Retirement::Products::Create::InitialIncome, call: nil) }
    let(:recommendation) { instance_double(Domain::Retirement::Recommendation::Builder, call: nil) }

    before do
      allow(Domain::Retirement::Products::Create::InitialIncome).to receive(:new).and_return(initial_income)

      allow(Domain::Retirement::Recommendation::Builder).to receive(:new).and_return(recommendation)

      described_class.call(mandate, questionnaire_response)
    end

    it { expect(questionnaire_response).to be_completed }
    it { expect(initial_income).to have_received(:call) }
    it { expect(recommendation).to have_received(:call) }
  end
end
