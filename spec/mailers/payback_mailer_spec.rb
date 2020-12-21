# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaybackMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, :payback_with_data, state: :created }
  let!(:unlocked_points) { Payback::Entities::PaybackTransaction::DEFAULT_POINTS_AMOUNT }
  let!(:category_name) { "test_category" }

  describe "#points_unlocked" do
    let(:mail) { PaybackMailer.points_unlocked(mandate, unlocked_points) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.points_unlocked }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#add_payback_number_reminder" do
    let(:mail) { PaybackMailer.add_payback_number_reminder(mandate) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.add_payback_number_reminder }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#inquiries_reminder" do
    let(:mail) { PaybackMailer.inquiries_reminder(mandate) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.payback_inquiries_reminder }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#inquiry_complete_reminder" do
    let(:mail) { PaybackMailer.inquiry_complete_reminder(mandate) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.payback_inquiry_complete_reminder }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#transaction_refunded" do
    let(:mail) { PaybackMailer.transaction_refunded(mandate, category_name) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.payback_transaction_refunded }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#inquiry_category_added" do
    let(:points_amount) { 750 }
    let(:mail) { PaybackMailer.inquiry_category_added(mandate, category_name, points_amount) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.payback_inquiry_category_added }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end
end
