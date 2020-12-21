# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Service::Varias do
  subject { described_class.new(questionnaire_response) }

  let(:questionnaire_response) { create :questionnaire_response }

  let!(:mock_config) do
    allow_any_instance_of(described_class).to receive(:config).and_return({})
  end

  let!(:mock_params_builder) do
    builder_class = Domain::Retirement::Service::Varias::PensionParams
    allow_any_instance_of(builder_class).to receive(:valid?).and_return(params_valid)
    allow_any_instance_of(builder_class).to receive(:errors).and_return([])
    allow_any_instance_of(builder_class).to receive(:params).and_return({})
  end

  let!(:mock_client) do
    client = double

    allow(client).to receive(:call).and_return(result)

    allow_any_instance_of(described_class).to receive(:client).and_return(client)
  end

  let(:values) do
    {
      "pensionAmountNet" => 100_000,
      "incomeBeforePensionAmountNet" => 150_000,
      "pensionGapAmountNet" => 50_000
    }
  end

  let(:success_result) do
    Domain::Retirement::Service::Varias::Result.new("200", values).call
  end

  let(:failure_result) do
    Domain::Retirement::Service::Varias::Result.new("400", {}).call
  end

  let(:retirement_calculation_result) do
    questionnaire_response.mandate.retirement_cockpit.retirement_calculation_result
  end

  describe "#calculate_pension" do
    context "when params are valid" do
      context "when client returns success" do
        let(:params_valid) { true }
        let(:result) { success_result }

        it "it returns successul result" do
          subject.calculate_pension
          expect(retirement_calculation_result.state).to eq("calculation_successful")
          expect(retirement_calculation_result.desired_income.to_f).to eq(100_000)
          expect(retirement_calculation_result.recommended_income.to_f).to eq(120_000)
          expect(retirement_calculation_result.retirement_gap.to_f).to eq(20_000)
        end
      end

      context "when client returns failure" do
        let(:params_valid) { true }
        let(:result) { failure_result }

        it "it returns successul result" do
          subject.calculate_pension
          expect(retirement_calculation_result.state).to eq("calculation_failed")
        end
      end
    end

    context "whene params are invalid" do
      let(:params_valid) { false }
      let(:result) { success_result }

      it "it returns successul result" do
        subject.calculate_pension
        expect(retirement_calculation_result.state).to eq("calculation_failed")
      end
    end
  end
end
