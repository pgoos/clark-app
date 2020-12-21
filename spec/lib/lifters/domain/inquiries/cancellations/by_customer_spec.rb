# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::Cancellations::ByCustomer do
  subject { Domain::Inquiries::Cancellations::ByCustomer.new(config) }

  let(:config) { {inquiry_category: inquiry_category, cause: cause} }
  let(:inquiry_category) { instance_double(InquiryCategory) }
  let(:cause) { nil }

  before do
    allow(inquiry_category).to receive(:is_a?).with(InquiryCategory).and_return(true)
  end

  context "when notification needed" do
    it "should not need a notification, if it is not cancelled" do
      allow(inquiry_category).to receive(:cancelled?).and_return(false)
      expect(subject).not_to be_notification_needed
    end

    it "should not need a notification, if it is cancelled" do
      allow(inquiry_category).to receive(:cancelled?).and_return(true)
      expect(subject).not_to be_notification_needed
    end
  end

  context "when cause injected" do
    it "defaults the cause to :cancelled_by_customer" do
      expect(subject.cause).to eq(:cancelled_by_customer)
    end

    it "picks up complete as a cause" do
      config[:cause] = :complete
      expect(subject.cause).to eq(:complete)
    end

    InquiryCategory.cancellation_causes.keys.map(&:to_sym).except(:cancelled_by_customer).each do |wrong_cause|
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

    it "should fail silently for multiple inquiry categories" do
      inquiry_category1 = instance_double(InquiryCategory)
      inquiry_category2 = instance_double(InquiryCategory)
      cancellations << double("cancellation1", inquiry_category: inquiry_category1)
      cancellations << double("cancellation2", inquiry_category: inquiry_category2)
      expect(described_class.build_mail(*cancellations)).to be_a(ActionMailer::Base::NullMail)
    end
  end
end
