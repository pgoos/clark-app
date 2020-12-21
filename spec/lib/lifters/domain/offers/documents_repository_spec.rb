# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Offers::DocumentsRepository, :integration do
  describe ".visible_plan_documents" do
    let(:parent_plan) { create(:parent_plan) }
    let(:mandate) { create :mandate, customer_state: "prospect" }
    let(:product) { create :product, mandate: mandate }

    let(:plan_document_types) do
      [
        DocumentType.general_insurance_conditions,
        DocumentType.produktinformationsblatt,
        DocumentType.specific_insurance_conditions,
        DocumentType.anzeigepflicht,
        DocumentType.product_terms_and_insurance_conditions,
        DocumentType.consultation_waives
      ]
    end

    let(:visible_plan_documents) do
      plan_document_types.map do |document_type|
        create(:document, documentable: parent_plan, document_type_id: document_type.id)
      end
    end

    let(:consultation_waives_document) do
      visible_plan_documents.find { |doc| doc.document_type_id == DocumentType.consultation_waives.id }
    end

    let(:other_document) do
      create(:document, documentable: parent_plan, document_type_id: DocumentType.advisory_documentation.id)
    end

    context "clark 1 customers" do
      let(:mandate) { create :mandate }

      it "does not return consultation_waives" do
        result = described_class.visible_plan_documents(parent_plan_id: parent_plan.id, product: product)

        expect(result).not_to include(consultation_waives_document)
      end
    end

    it "returns only plan documents" do
      result = described_class.visible_plan_documents(parent_plan_id: parent_plan.id, product: product)

      expect(result).to match_array(visible_plan_documents)
      expect(result).not_to include(other_document)
    end

    it "returns consultation_waives documents for prospect customer" do
      result = described_class.visible_plan_documents(parent_plan_id: parent_plan.id, product: product)

      expect(result).to include(consultation_waives_document)
    end

    it "returns consultation_waives documents for self_service customer" do
      product.mandate.update!(customer_state: "self_service")
      result = described_class.visible_plan_documents(parent_plan_id: parent_plan.id, product: product)

      expect(result).to include(consultation_waives_document)
    end

    it "does not return consultation_waives documents for mandate_customer customer" do
      product.mandate.update!(customer_state: "mandate_customer")
      result = described_class.visible_plan_documents(parent_plan_id: parent_plan.id, product: product)

      expect(result).not_to include(consultation_waives_document)
    end

    it "does not return consultation_waives documents for customer with customer_state nil" do
      product.mandate.update!(customer_state: nil)
      result = described_class.visible_plan_documents(parent_plan_id: parent_plan.id, product: product)

      expect(result).not_to include(consultation_waives_document)
    end
  end

  describe ".plan_document?" do
    context "when plan document_type" do
      let(:general_insurance_conditions_document_type) { DocumentType.general_insurance_conditions }
      let(:consultation_waives_document_type) { DocumentType.consultation_waives }

      it "returns true for general_insurance_conditions type" do
        expect(described_class.plan_document?(general_insurance_conditions_document_type.id)).to eq(true)
      end

      it "returns true for consultation_waives type" do
        expect(described_class.plan_document?(consultation_waives_document_type.id)).to eq(true)
      end
    end

    context "when not a plan document_type" do
      let(:document_type) { DocumentType.advisory_documentation }

      it "returns false" do
        expect(described_class.plan_document?(document_type.id)).to eq(false)
      end
    end
  end
end
