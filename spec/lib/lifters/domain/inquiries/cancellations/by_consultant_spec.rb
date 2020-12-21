# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::Cancellations::ByConsultant do
  let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }

  before do
    allow(messenger_class)
      .to receive(:inquiry_categories_cancelled)
      .with(InquiryCategory)
  end

  context "when mail is built" do
    let(:cancellations) { [] }

    context "when sending mails" do
      it "should fail silently, if there are no inquiry categories" do
        expect(described_class.build_mail(*cancellations)).to be_a(ActionMailer::Base::NullMail)
      end

      it "should forward a single inquiry category to the mailer" do
        inquiry_category = instance_double(InquiryCategory)
        cancellations << double("cancellation1", inquiry_category: inquiry_category)
        expect(InquiryCategoryMailer).to receive(:inquiry_categories_cancelled).with(inquiry_category)
        described_class.build_mail(*cancellations)
      end

      it "should forward multiple inquiry categories to the mailer" do
        inquiry_category1 = instance_double(InquiryCategory)
        inquiry_category2 = instance_double(InquiryCategory)
        cancellations << double("cancellation1", inquiry_category: inquiry_category1)
        cancellations << double("cancellation2", inquiry_category: inquiry_category2)
        expect(InquiryCategoryMailer)
          .to receive(:inquiry_categories_cancelled)
          .with(inquiry_category1, inquiry_category2)
        described_class.build_mail(*cancellations)
      end
    end

    context "when sending the messenger messages" do
      it "should forward a given inquiry category to the mailer" do
        inquiry_category = instance_double(InquiryCategory)
        allow(inquiry_category).to receive(:is_a?).with(InquiryCategory).and_return(true)

        expect(messenger_class).to receive(:inquiry_categories_cancelled).with(inquiry_category)

        subject = described_class.new(inquiry_category: inquiry_category, cause: :contract_not_found)
        subject.send_messenger_message
      end
    end
  end
end
