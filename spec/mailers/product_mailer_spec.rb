# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: user, state: :created }
  let(:user)     { create :user, email: email, subscriber: true }
  let(:email)    { "whitfielddiffie@gmail.com" }
  let(:product)  { create :product, mandate: mandate }
  let(:documentable) { product }

  describe "#smartphone_insurance_confirmation_email" do
    let(:mail) { ProductMailer.smartphone_insurance_confirmation_email(product) }
    let(:document_type) { DocumentType.smartphone_insurance_confirmation }

    include_examples "checks mail rendering"
    include_examples "does not send out an email if mandate belongs to the partner"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#offered_product_available" do
    let(:mail) { ProductMailer.offered_product_available(product) }
    let(:document_type) { DocumentType.offered_product_available }

    include_examples "checks mail rendering"
    include_examples "does not send out an email if mandate belongs to the partner"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#advisory_documentation_available" do
    let(:mail) { ProductMailer.advisory_documentation_available(product) }
    let(:document_type) { DocumentType.advisory_documentation }

    include_examples "checks mail rendering"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#dental_insurance" do
    let(:mail) { ProductMailer.smartphone_insurance_confirmation_email(product) }
    let(:document_type) { DocumentType.smartphone_insurance_confirmation }

    include_examples "checks mail rendering"

    describe "with ahoy email tracking" do
      it "includes the tracking pixel" do
        expect(mail.body.encoded).to include("open.gif")
      end

      it "replaces links with tracking links", skip: "Failing because of changed encoding"  do
        original_link       = "https://www.facebook.com/ClarkGermany"
        tracking_parameters = "utm_campaign=smartphone_insurance_confirmation_email&utm_medium=email&utm_source=product_mailer"
        tracking_link       = /http:\/\/test.host\/ahoy\/messages\/\w{32}\/click\?signature=\w{40}&amp;url=#{CGI.escape(original_link + "?" + tracking_parameters)}/
        expect(mail.body.encoded).to match(tracking_link)
      end

      include_examples "stores a message object upon delivery", "ProductMailer#smartphone_insurance_confirmation_email", "product_mailer", "smartphone_insurance_confirmation_email"
      include_examples "tracks document and mandate in ahoy email"
    end
  end

  describe "no_email_available_for_suhk_product_termination" do
    let(:mail) { ProductMailer.no_email_available_for_suhk_product_termination(product) }
    let(:document_type) { DocumentType.no_email_available_for_suhk_product_termination }

    it "renders the email successfully" do
      expect(mail.body.encoded).not_to be_nil
    end

    include_examples "send out an email if mandate belongs to the partner"
  end

  describe "#suhk_product_termination" do
    let(:mail) { ProductMailer.suhk_product_termination("insr@example.com", product) }
    let(:document_type) { DocumentType.suhk_product_termination }

    it "renders the email successfully" do
      expect(mail.body.encoded).not_to be_nil
    end

    include_examples "send out an email if mandate belongs to the partner"
  end

  describe "#request_document_reupload" do
    let(:mail) { ProductMailer.request_document_reupload(product) }
    let(:document_type) { DocumentType.request_document_reupload }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#offered_product_available" do
    let(:mail) { ProductMailer.offered_product_available(product) }
    let(:document_type) { DocumentType.offered_product_available }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#advisory_documentation_available" do
    let(:mail) { ProductMailer.advisory_documentation_available(product) }
    let(:document_type) { DocumentType.advisory_documentation_available }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end
end
