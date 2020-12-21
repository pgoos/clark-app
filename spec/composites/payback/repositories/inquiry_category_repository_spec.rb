# frozen_string_literal: true

require "rails_helper"
require "composites/payback/repositories/inquiry_category_repository"

RSpec.describe Payback::Repositories::InquiryCategoryRepository do
  subject(:repository) { described_class.new }

  let(:mandate) { create(:mandate) }

  let(:inquiry) {
    create(
      :inquiry,
      mandate: mandate
    )
  }

  let(:inquiry_category) {
    create(
      :inquiry_category,
      :in_progress,
      inquiry: inquiry
    )
  }

  describe "#find" do
    it "returns entity with aggregated data" do
      entity = repository.find(inquiry_category.id)
      expect(entity).to be_kind_of Payback::Entities::InquiryCategory

      expect(entity.id).to eq(inquiry_category.id)
      expect(entity.mandate_id).to eq(mandate.id)
      expect(entity.state).to eq "in_progress"

      expect(entity.be_rewardable).to be_truthy
    end

    context "when inquiry category does not exist" do
      it "returns nil" do
        expect(repository.find(9999)).to be_nil
      end
    end

    context "when inquiry category is not associated to an inquiry" do
      let(:inquiry_category) {
        create(
          :inquiry_category,
          inquiry: nil
        )
      }

      it "returns entity with nil attributes related to inquiry" do
        entity = repository.find(inquiry_category.id)
        expect(entity).to be_kind_of Payback::Entities::InquiryCategory

        expect(entity.id).to eq(inquiry_category.id)
        expect(entity.mandate_id).to be_nil
        expect(entity.company_name).to be_nil
        expect(entity.inquiry_state).to be_nil
      end
    end
  end

  describe "#find_by_customer" do
    it "returns array with InquiryCategory entities associated to customer and state" do
      inquiry_categories = repository.find_by_customer(inquiry_category.mandate.id, inquiry_category.state)

      expect(inquiry_categories).to be_kind_of(Array)
      expect(inquiry_categories[0]).to be_kind_of(Payback::Entities::InquiryCategory)
      expect(inquiry_categories[0].id).to eq(inquiry_category.id)
    end

    context "when customer does not exist" do
      let(:state) { Payback::Entities::InquiryCategory::PAYBACK_REWARDABLE_STATES.first }

      it "returns nil" do
        expect(repository.find_by_customer(9999, state)).to eq([])
      end
    end
  end

  describe "#find_by_inquiry" do
    let(:state) { "in_progress" }

    it "returns array with InquiryCategory entities associated to inquiry with the right state" do
      inquiry_categories = repository.find_by_inquiry(inquiry_category.inquiry.id, state)

      expect(inquiry_categories).to be_kind_of(Array)
      expect(inquiry_categories[0]).to be_kind_of(Payback::Entities::InquiryCategory)
      expect(inquiry_categories[0].id).to eq(inquiry_category.id)
    end

    context "when there is not any inquiry category associated to specific inquiry_id" do
      it "returns nil" do
        expect(repository.find_by_customer(9999, state)).to eq([])
      end
    end
  end

  describe "#be_rewardable" do
    context "inquiry category is in the rewardable state" do
      it "returns true" do
        entity = repository.find(inquiry_category.id)
        expect(entity.be_rewardable).to be_truthy
      end
    end

    context "inquiry category is in canceled state" do
      let(:canceled_inquiry_category) {
        create(
          :inquiry_category,
          :cancelled_by_customer
        )
      }

      it "returns false" do
        entity = repository.find(canceled_inquiry_category.id)
        expect(entity.be_rewardable).to be_falsey
      end
    end
  end

  describe "#by_customer_created_before" do
    let(:mandate) { create(:mandate, :payback_with_data) }
    let(:first_inquiry) { create(:inquiry, mandate: mandate) }
    let(:second_inquiry) { create(:inquiry) }
    let!(:first_inquiry_category) {
      create(:inquiry_category, inquiry: first_inquiry, created_at: DateTime.now - 2.days)
    }
    let!(:second_inquiry_category) {
      create(:inquiry_category, inquiry: first_inquiry, created_at: DateTime.now)
    }
    let!(:third_inquiry_category) {
      create(:inquiry_category, inquiry: second_inquiry, created_at: DateTime.now - 2.days)
    }

    it "returns one inquiry_category" do
      inquiry_categories = repository.by_customer_created_before(mandate.id, DateTime.now - 1.day)

      expect(inquiry_categories.length).to eq(1)
      expect(inquiry_categories[0]).to be_kind_of(Payback::Entities::InquiryCategory)
      expect(inquiry_categories[0].id).to eq(first_inquiry_category.id)
    end
  end

  describe "#was_completed??" do
    let(:canceled_inquiry_category) {
      create(
        :inquiry_category,
        :cancelled_by_customer
      )
    }

    context "when inquiry_category was completed before" do
      let!(:business_event) { create(:business_event, action: "complete", entity: canceled_inquiry_category) }

      it "returns true" do
        expect(repository.was_completed?(canceled_inquiry_category.id)).to be_truthy
      end
    end

    context "when inquiry_category wasn't completed" do
      it "returns false" do
        expect(repository.was_completed?(canceled_inquiry_category.id)).to be_falsey
      end
    end
  end

  describe "#not_rewarded_ids" do
    let(:mandate) { create(:mandate, :payback_with_data) }
    let(:inquiry) { create(:inquiry, mandate: mandate) }
    let(:states) { Payback::Entities::InquiryCategory::PAYBACK_REWARDABLE_STATES }

    context "when inquiry category was not rewarded" do
      let!(:inquiry_category) { create(:inquiry_category, inquiry: inquiry) }

      it "returns customer id" do
        expect(repository.not_rewarded_ids(mandate.id, states)).to match_array([inquiry_category.id])
      end
    end

    context "when inquiry category was already rewarded" do
      let!(:inquiry_category) { create(:inquiry_category, inquiry: inquiry) }
      let!(:payback_transactions) { create(:payback_transaction, :book, subject: inquiry_category) }

      it { expect(repository.not_rewarded_ids(mandate.id, states)).to match_array([]) }
    end

    context "when inquiry category is not associated to the customer" do
      let!(:inquiry_category) { create(:inquiry_category) }

      it { expect(repository.not_rewarded_ids(mandate.id, states)).to match_array([]) }
    end

    context "when inquiry category has different state from the ones passed in arguments" do
      let!(:inquiry_category) { create(:inquiry_category, inquiry: inquiry, state: "in_progress") }

      it { expect(repository.not_rewarded_ids(mandate.id, ["completed"])).to match_array([]) }
    end
  end
end
