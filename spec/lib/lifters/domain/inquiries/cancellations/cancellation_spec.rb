# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::Cancellations::Cancellation do
  subject { Domain::Inquiries::Cancellations::ByConsultant.new(config) } # using this class as a standard case

  let(:config) { {inquiry_category: inquiry_category, cause: cause} }
  let(:inquiry_category) { build_stubbed(:inquiry_category, :shallow, :in_progress) }
  let(:cause) { :contract_not_found }

  before do
    allow(inquiry_category).to receive(:is_a?).with(InquiryCategory).and_return(true)
    allow(inquiry_category).to receive(:mandate_accepted?).and_return(true)
  end

  context "when cancellation_excluded?" do
    it "defaults to false" do
      expect(subject.class.cancellation_excluded?).to eq(false)
    end
  end

  context "when finalized" do
    it "should do the cancellation" do
      expect(inquiry_category).to receive("cancel_because_#{cause}!".to_sym)
      subject.finalize!
    end

    it "should save reason for custom cancellation" do
      config[:cause] = :custom
      config[:custom_cancel_reason] = "custom_cancel_reason"
      allow(inquiry_category).to receive(:update_column)
      expect(inquiry_category).to receive(:cancel_because_custom!)
      expect(inquiry_category).to receive(:update_column).with(:custom_cancellation_reason, "custom_cancel_reason")
      subject.finalize!
    end

    it "should do the completion" do
      config[:cause] = :complete
      expect(inquiry_category).to receive(:complete!)
      subject.finalize!
    end

    context "when object is cancelled already" do
      let(:inquiry_category) { build_stubbed(:inquiry_category, :shallow, :cancelled_by_customer) }

      it "should not try a finalization" do
        expect(inquiry_category).not_to receive("cancel_because_#{cause}!".to_sym)
        subject.finalize!
      end
    end

    context "when object is completed already" do
      let(:inquiry_category) { build_stubbed(:inquiry_category, :shallow, :completed) }

      it "should not try a finalization" do
        config[:cause] = :complete
        expect(inquiry_category).not_to receive(:complete!)
        subject.finalize!
      end
    end
  end

  context "when notification needed" do
    it "should not need a notification, if it is not cancelled" do
      allow(inquiry_category).to receive(:cancelled?).and_return(false)
      expect(subject).not_to be_notification_needed
    end

    it "should need a notification, if it is cancelled" do
      allow(inquiry_category).to receive(:cancelled?).and_return(true)
      expect(subject).to be_notification_needed
    end

    it "should not need a notification, if the customer is not accepted" do
      allow(inquiry_category).to receive(:cancelled?).and_return(true)
      allow(inquiry_category).to receive(:mandate_accepted?).and_return(false)
      expect(subject).not_to be_notification_needed
    end
  end
end
