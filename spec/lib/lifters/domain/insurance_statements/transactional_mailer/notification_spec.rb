# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::InsuranceStatements::TransactionalMailer::Notification do
  subject { described_class }

  let(:mandate) { FactoryBot.build(:mandate) }

  describe ".notify" do
    it "should send a push notification with an SMS fallback" do
      expect_any_instance_of(OutboundChannels::PushWithSmsFallback).to receive(:send_message)
      subject.notify(mandate)
    end
  end
end
