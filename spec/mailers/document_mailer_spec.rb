# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: user, state: :created }
  let!(:user) { create :user, email: email, subscriber: true }
  let!(:email) { "whitfielddiffie@gmail.com" }
  let!(:category) { create(:category) }
  let!(:opportunity) { create :shallow_opportunity, category: category }
  let(:product) { create :product, mandate: mandate }
  let(:documentable) { opportunity }

  describe "#document_general_insurance_conditions_notification" do
    let(:document_type) { DocumentType.general_insurance_conditions_notification }
    let(:document) { create :document, documentable: opportunity, document_type: document_type }
    let!(:mail) { DocumentMailer.general_insurance_conditions_notification(mandate, document) }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#document_product_application_fully_signed" do
    let(:document_type) { DocumentType.product_application_fully_signed }
    let(:document) { create :document, documentable: opportunity, document_type: document_type }
    let(:mail) { DocumentMailer.product_application_fully_signed(mandate, document) }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#important_documents_notification" do
    let(:document_type) { DocumentType.important_documents_notification }
    let(:document) { create :document, documentable: product, document_type: document_type }
    let(:mail) { DocumentMailer.important_documents_notification(mandate, document) }

    include_examples "checks mail rendering"
    include_examples "stores a message object upon delivery", "DocumentMailer#important_documents_notification", "document_mailer", "important_documents_notification"
  end
end
