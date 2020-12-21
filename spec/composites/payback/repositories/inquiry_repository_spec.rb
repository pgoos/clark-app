# frozen_string_literal: true

require "rails_helper"
require "composites/payback/repositories/inquiry_repository"

RSpec.describe Payback::Repositories::InquiryRepository do
  subject(:repository) { described_class.new }

  let(:mandate) { create(:mandate, :payback_with_data) }

  let(:inquiry) {
    create(
      :inquiry,
      mandate: mandate
    )
  }

  describe "#find" do
    it "returns entity with aggregated data" do
      entity = repository.find(inquiry.id)
      expect(entity).to be_kind_of Payback::Entities::Inquiry

      expect(entity.id).to eq(inquiry.id)
      expect(entity.state).to eq(inquiry.state)
      expect(entity.customer).to be_nil
    end

    context "when the include customer is forced" do
      it "returns entity including customer" do
        entity = repository.find(inquiry.id, include_customer: true)

        expect(entity).to be_kind_of Payback::Entities::Inquiry
        expect(entity.customer).to be_kind_of Payback::Entities::Customer
        expect(entity.customer.id).to eq inquiry.mandate_id
      end
    end

    context "when inquiry category does not exist" do
      it "returns nil" do
        expect(repository.find(9999)).to be_nil
      end
    end
  end
end
