# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Documents::ParentPlansPermissionRepository, :integration do
  subject { described_class.new(mandate) }

  let(:mandate) { create(:mandate) }

  describe "#find" do
    context "when user is allowed" do
      let(:document1) { create(:document, documentable: parent_plan1) }
      let!(:product) { create(:product, plan: plan, mandate: mandate) }
      let(:plan) { create(:plan, parent_plan: parent_plan1) }
      let(:parent_plan1) { create(:parent_plan) }
      let(:parent_plan2) { create(:parent_plan) }

      it "returns the correct document" do
        document = subject.find(document_id: document1.id, parent_plan_id: parent_plan1.id)
        expect(document).to eq document1

        document = subject.find(document_id: document1.id, parent_plan_id: parent_plan2.id)
        expect(document).to be_nil
      end
    end

    context "when document is offered product's plan document" do
      let(:parent_plan) { create(:parent_plan) }
      let(:document_type) { DocumentType.general_insurance_conditions }
      let!(:document) { create(:document, document_type: document_type, documentable: parent_plan) }

      it "returns the document" do
        result = subject.find(document_id: document.id, parent_plan_id: parent_plan.id)
        expect(result).to eq document
      end
    end
  end
end
