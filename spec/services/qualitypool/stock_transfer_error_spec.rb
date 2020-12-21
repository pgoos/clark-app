# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qualitypool::StockTransferError do
  describe "#metadata" do
    let(:errors) { ["error1"] }
    let(:skipped_actions) { ["person"] }
    let(:actions) { ["document"] }

    it "returns the correct metadata" do
      exception = described_class.new(errors: errors, skipped_actions: skipped_actions, actions: actions)
      metadata = exception.metadata
      expect(metadata[:errors]).to eq errors
      expect(metadata[:skipped_actions]).to eq skipped_actions
      expect(metadata[:actions]).to eq actions
      expect(metadata[:time].to_time).to be_instance_of ::Time
    end
  end

  describe "#message" do
    let(:errors) { ["Error1"] }

    it "gets the message from error when cause is nil" do
      error_message = "Error"
      begin
        raise error_message
      rescue RuntimeError
        begin
          raise described_class.new
        rescue described_class => e
          exception = e
        end
      end
      expect(exception.message).to eq error_message
      expect(exception.original_exception.message).to eq error_message
    end

    it "shows the transfer errors" do
      begin
        raise described_class.new(errors: errors)
      rescue described_class => e
        exception = e
      end

      error_message = "Error in transfer #{errors}"
      expect(exception.message).to eq error_message
      expect(exception.original_exception.message).to eq error_message
    end
  end
end
