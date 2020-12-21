# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Ops::Report::RunnerJob do
  describe "#perform_now" do
    let(:report) do
      {
        name: "Sample Report",
        class: "Sample",
        time: "07:00"
      }
    end

    context "when scheduled with arguments" do
      it "calls ::Domain::Ops::Report::Runner when scheduled" do
        expect(
          ::Domain::Ops::Report::Runner
        ).to receive(:run).with(report)

        described_class.perform_now(report)
      end
    end
  end
end
