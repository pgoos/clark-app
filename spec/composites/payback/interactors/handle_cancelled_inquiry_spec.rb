# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/handle_cancelled_inquiry"
require "composites/payback/repositories/inquiry_repository"
require "composites/payback/repositories/inquiry_category_repository"

RSpec.describe Payback::Interactors::HandleCancelledInquiry, :integration do
  subject {
    described_class.new(
      inquiry_category_repo: inquiry_category_repo,
      inquiry_repo: inquiry_repo
    )
  }

  let(:inquiry_repo) do
    instance_double(
      Payback::Repositories::InquiryRepository,
      find: inquiry
    )
  end

  let(:inquiry) { double(id: 1, state: "canceled", customer: customer) }

  let(:customer) { build(:payback_customer_entity, :accepted, :with_payback_data) }

  let(:inquiry_category) { build(:payback_inquiry_category_entity) }

  let(:inquiry_category_repo) do
    instance_double(
      Payback::Repositories::InquiryCategoryRepository,
      find_by_inquiry: [inquiry_category]
    )
  end

  let(:handle_cancelled_inquiry_category_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false
    )
  end

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
    allow(Payback).to receive(:handle_cancelled_inquiry_category).and_return(handle_cancelled_inquiry_category_result)
  end

  context "when all the validation are okay" do
    it "result should be successful" do
      result = subject.call(inquiry.id)

      expect(result).to be_kind_of Utils::Interactor::Result
      expect(result).to be_successful
    end

    it "should initiate the handle of inquiry category from the interactor" do
      expect(Payback).to receive(:handle_cancelled_inquiry_category).with(inquiry_category.id)

      subject.call(inquiry.id)
    end

    it "should find the inquiry with the right id through the repo" do
      expect(inquiry_repo).to receive(:find).with(inquiry.id, include_customer: true)

      subject.call(inquiry.id)
    end
  end

  context "when customer of inquiry is not payback one " do
    before do
      allow(customer).to receive(:payback_enabled).and_return(false)
    end

    it "result should not be successful" do
      result = subject.call(inquiry.id)

      expect(result).not_to be_successful
    end
  end
end
