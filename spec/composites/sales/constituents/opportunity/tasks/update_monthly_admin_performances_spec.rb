# frozen_string_literal: true

require "rails_helper"

require "composites/sales"

RSpec.describe "aoa:update_monthly_admin_performances", type: :task do
  context "feature AOA_BASED_CONSULTANT_ASSIGNMENT enabled" do
    before do
      allow(Features).to receive(:active?).with(Features::AOA_BASED_CONSULTANT_ASSIGNMENT).and_return(true)
      allow(Sales).to receive(:generate_historical_monthly_admin_performance)
    end

    context "task successes" do
      it "calls generate_historical_monthly_admin_performance in Sales module and prints the correct string" do
        expect(Sales).to receive(:generate_historical_monthly_admin_performance)
        expect(Rails.logger).to receive(:info)

        task.invoke
      end
    end

    context "task fails" do
      let(:error) { StandardError.new("Something happened") }

      before do
        allow(Sales).to receive(:generate_historical_monthly_admin_performance).and_raise(error)
      end

      it "logs error with Raven" do
        expect(Raven)
          .to receive(:capture_message)
          .with(
            error,
            { extra:
              { error_message: "update_monthly_admin_performances failed: #{error.message}" },
              level: "error" }
          )
        expect(Rails.logger).to receive(:error).with("update_monthly_admin_performances failed: #{error.message}")

        task.invoke
      end
    end
  end

  context "feature AOA_BASED_CONSULTANT_ASSIGNMENT disabled" do
    before do
      allow(Features).to receive(:active?).with(Features::AOA_BASED_CONSULTANT_ASSIGNMENT).and_return(false)
    end

    it "triggers generate historical monthly admin performance interactor" do
      expect(Sales).not_to receive(:generate_historical_monthly_admin_performance)
      task.invoke
    end
  end
end
