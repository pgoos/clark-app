# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Entities::InquiryCategory do
  subject { described_class }
  let(:inquiry_category) { create(:inquiry_category) }
  let(:document) { FactoryBot.build_stubbed(:document, documentable: inquiry_category) }

  it { is_expected.to expose(:category_ident).of(inquiry_category).as(String) }
  it { is_expected.to expose(:documents).of(inquiry_category).as(Array) }


  context "cancellation" do
    before do
      inquiry_category.cancel_because_insurer_denied_information_access
    end

    it "expose state" do
      is_expected.to expose(:state).of(inquiry_category).as(String)
    end

    it "expose cancelation_cause" do
      is_expected.to expose(:cancellation_cause).of(inquiry_category).as(String)
    end

    it "expose message" do
      content_key = "activerecord.attributes.inquiry" \
                    ".cancellation_cause.#{inquiry_category.cancellation_cause}"
      expected_message = I18n.t(content_key)
      is_expected.to expose(:cancellation_cause_message).of(inquiry_category)
                                                       .as(String)
                                                       .with_value(expected_message)
    end
  end
end
