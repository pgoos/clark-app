# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::ManualStateReset do
  subject { described_class.new.(product) }

  let(:product) { create :product, state: "takeover_requested" }

  context "when manually products state reset" do
    it "triggers new custom business event" do
      expect(BusinessEvent).to receive(:audit).with(product, ::Domain::Products::ManualStateReset::MANUAL_STATE_RESET)

      subject
    end
  end
end
