# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::Cancellations::ByTimeout do
  subject { Domain::Inquiries::Cancellations::ByTimeout.new(config) }

  let(:config) { {inquiry_category: inquiry_category, cause: cause} }
  let(:inquiry_category) { instance_double(InquiryCategory) }
  let(:cause) { nil }
  let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }

  before do
    allow(inquiry_category).to receive(:is_a?).with(InquiryCategory).and_return(true)
    allow(inquiry_category).to receive(:mandate_accepted?).and_return(true)
    allow(messenger_class)
      .to receive(:inquiry_category_timed_out)
      .with(InquiryCategory)
  end

  context "when notification needed" do
    it "should not need a notification, if it is not cancelled" do
      allow(inquiry_category).to receive(:cancelled?).and_return(false)
      expect(subject).not_to be_notification_needed
    end

    it "should not need a notification, if it is cancelled" do
      allow(inquiry_category).to receive(:cancelled?).and_return(true)
      expect(subject).to be_notification_needed
    end
  end

  context "when cause injected" do
    it "defaults the cause to :cancelled_by_customer" do
      expect(subject.cause).to eq(:timed_out)
    end

    it "picks up complete as a cause" do
      config[:cause] = :complete
      expect(subject.cause).to eq(:complete)
    end

    InquiryCategory.cancellation_causes.keys.map(&:to_sym).except(:timed_out).each do |wrong_cause|
      it "does not accept the cause #{wrong_cause}" do
        config[:cause] = wrong_cause
        expect { subject.cause }.to raise_error("Can't process cause #{wrong_cause}! Use a different class!")
      end
    end
  end

  context "when mail is built" do
    let(:cancellations) { [] }

    it "should fail silently, if there are no inquiry categories" do
      expect(described_class.build_mail(*cancellations)).to be_a(ActionMailer::Base::NullMail)
    end

    it "should forward a single inquiry category" do
      inquiry_category = instance_double(InquiryCategory)
      cancellations << double("cancellation1", inquiry_category: inquiry_category)
      expect(InquiryCategoryMailer).to receive(:inquiry_categories_timed_out).with(inquiry_category)
      described_class.build_mail(*cancellations)
    end

    it "should forward multiple inquiry categories" do
      inquiry_category1 = instance_double(InquiryCategory)
      inquiry_category2 = instance_double(InquiryCategory)
      cancellations << double("cancellation1", inquiry_category: inquiry_category1)
      cancellations << double("cancellation2", inquiry_category: inquiry_category2)
      expect(InquiryCategoryMailer).to receive(:inquiry_categories_timed_out).with(inquiry_category1, inquiry_category2)
      described_class.build_mail(*cancellations)
    end
  end

  context "when sending the messenger messages" do
    it "should forward a given inquiry category to the mailer" do
      expect(messenger_class).to receive(:inquiry_category_timed_out).with(inquiry_category)

      subject = described_class.new(inquiry_category: inquiry_category, cause: :timed_out)
      subject.send_messenger_message
    end
  end

  context "when cancellation excluded" do
    let(:timeout_feature_switch) { Features::FEATURE_AUTO_CANCEL_INQUIRIES_AFTER_TIMEOUT }

    before do
      allow(Features).to receive(:active?).with(any_args).and_return(false)
    end

    it "should cancel, if the feature is switched on" do
      allow(Features).to receive(:active?).with(timeout_feature_switch).and_return(true)
      expect(described_class).not_to be_cancellation_excluded
    end

    it "should not cancel, if the timeout feature is switched off" do
      allow(Features).to receive(:active?).with(timeout_feature_switch).and_return(false)
      expect(described_class).to be_cancellation_excluded
    end
  end
end
