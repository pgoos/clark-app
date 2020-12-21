# frozen_string_literal: true

require "rails_helper"

describe Domain::Inquiries::DocumentRepository, integration: true do
  let(:mandate) { create :mandate, :accepted }

  describe "#all" do
    it do
      document = create(:document, :customer_upload)
      inquiry = create(:inquiry, documents: [document], mandate: mandate)

      expect(subject.all).to eq [inquiry]
    end

    context "with inquiry not open (state not in in_creation pending contacted)" do
      it do
        document = create(:document, :customer_upload)
        create(:inquiry, documents: [document], state: :canceled, mandate: mandate)

        expect(subject.all).to be_empty
      end
    end

    context "with inquiry_category relation" do
      it do
        inquiry_category = create(:inquiry_category)
        document = create(:document, :customer_upload)
        create(:inquiry, documents: [document], inquiry_categories: [inquiry_category], mandate: mandate)

        expect(subject.all).to be_empty
      end
    end

    context "with document_type not being customer_upload" do
      it do
        document = create(:document, :advisory_documentation)
        create(:inquiry, documents: [document], mandate: mandate)

        expect(subject.all).to be_empty
      end
    end
  end
end
