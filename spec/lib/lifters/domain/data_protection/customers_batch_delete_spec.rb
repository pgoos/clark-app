# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::CustomersBatchDelete do
  before do
    allow(Settings.ops_ui.mandate).to(
      receive(:delete_enabled).and_return(delete_enabled)
    )
    allow(Settings.ops_ui.mandate).to(
      receive(:batch_delete_enabled).and_return(batch_delete_enabled)
    )
  end

  let(:delete_enabled) { true }
  let(:batch_delete_enabled) { true }

  describe ".call" do
    context "when functionality is enabled" do
      it "creates a delayed job" do
        allow(described_class).to receive(:enabled?).and_return(true)

        expect(::DataProtection::CustomersBatchDeleteJob).to(
          receive(:perform_later)
        )

        described_class.call
      end
    end

    context "when functionality is enabled" do
      it "raises an error" do
        allow(described_class).to receive(:enabled?).and_return(false)

        expect { described_class.call }.to raise_error(StandardError, "Customer command disabled")
      end
    end
  end

  describe ".enabled?" do
    context "when delete_enabled = false" do
      let(:delete_enabled) { false }
      let(:batch_delete_enabled) { true }

      it "returns false" do
        expect(described_class).not_to be_enabled
      end
    end

    context "when batch_delete_enabled = false" do
      let(:delete_enabled) { true }
      let(:batch_delete_enabled) { false }

      it "returns false" do
        expect(described_class).not_to be_enabled
      end
    end

    context "when both settings are false" do
      let(:delete_enabled) { false }
      let(:batch_delete_enabled) { false }

      it "returns false" do
        expect(described_class).not_to be_enabled
      end
    end

    context "when both settings are true" do
      let(:delete_enabled) { true }
      let(:batch_delete_enabled) { true }

      it "returns true" do
        expect(described_class).to be_enabled
      end
    end
  end
end
