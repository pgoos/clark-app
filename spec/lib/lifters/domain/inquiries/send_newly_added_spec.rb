# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::SendNewlyAdded do
  subject(:send_inquiries) { described_class.new inquiry_sender: inquiry_sender }

  let(:inquiry_sender) do
    object_double Domain::Inquiries::InitialContacts.new, send_insurance_requests: nil
  end

  let(:inquiry_categories) do
    (1..3).map { |id| object_double(InquiryCategory.new, category_id: id) }
  end

  let(:mandate) { object_double Mandate.new, accepted?: true, sendable_inquiries: [inquery] }
  let(:inquery) { object_double Inquiry.new, inquiry_categories: inquiry_categories }

  before do
    allow_any_instance_of(ActiveRecord::Associations::Preloader).to receive(:preload)
    send_inquiries.(mandate)
  end

  it "sends inquiries to insurers" do
    expect(inquiry_sender).to have_received(:send_insurance_requests).with([inquery])
  end

  context "when there are 2 the same category in inquiry" do
    let(:inquiry_categories) do
      [
        object_double(InquiryCategory.new, category_id: 1),
        object_double(InquiryCategory.new, category_id: 1)
      ]
    end

    it "does not send inquiry to insurer" do
      expect(inquiry_sender).not_to have_received(:send_insurance_requests).with([inquery])
    end
  end

  context "when there are more then 3 categories in inquiry" do
    let(:inquiry_categories) do
      (1..4).map { |id| object_double(InquiryCategory.new, category_id: id) }
    end

    it "does not send inquiry to insurer" do
      expect(inquiry_sender).not_to have_received(:send_insurance_requests).with([inquery])
    end
  end

  context "when mandate is not accepted" do
    let(:mandate) { object_double Mandate.new, accepted?: false, sendable_inquiries: [inquery] }

    it "does not send any inquiries to insurers" do
      expect(inquiry_sender).not_to have_received(:send_insurance_requests).with([inquery])
    end
  end
end
