# frozen_string_literal: true

require "rails_helper"

describe Domain::Inquiries::InquiryObserver do
  describe "#send_inquiry_cancelled" do
    let(:inquiry) { create(:inquiry) }

    before do
      allow(Payback).to receive(:handle_cancelled_inquiry).and_return true
    end

    it "call the method on payback composite to handle cancelled inquiry event" do
      expect(Payback).to receive(:handle_cancelled_inquiry).with(inquiry.id)

      described_class.send_inquiry_cancelled(inquiry)
    end
  end
end
