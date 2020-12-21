# frozen_string_literal: true

require "rails_helper"

RSpec.describe InquiryCategoryMailer, :integration, type: :mailer do
  let(:mandate) { build :mandate, user: user, state: :created }
  let(:user) { build :user, email: email, subscriber: true }
  let(:email)  { "whitfielddiffie@gmail.com" }
  let(:inquiry) { build(:inquiry, mandate: mandate) }
  let(:category) { build(:category) }
  let(:inquiry_category) { create(:inquiry_category, category: category, inquiry: inquiry) }
  let(:documentable) { mandate }

  describe "#inquiry_category_inquiry_categories_cancelled" do
    let(:mail) { InquiryCategoryMailer.inquiry_categories_cancelled(inquiry_category) }
    let(:document_type) { DocumentType.inquiry_categories_cancelled }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#inquiry_category_inquiry_categories_timed_out" do
    let(:mail) { InquiryCategoryMailer.inquiry_categories_timed_out(inquiry_category) }
    let(:document_type) { DocumentType.inquiry_categories_timed_out }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#inquiry_category_no_product_can_be_created" do
    let(:possible_reasons) { [] }
    let(:additional_information) { "Test" }
    let(:mail) { InquiryCategoryMailer.no_product_can_be_created(inquiry_category, possible_reasons, additional_information) }
    let(:document_type) { DocumentType.no_product_can_be_created }
    let(:documentable) { inquiry_category }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end
end
