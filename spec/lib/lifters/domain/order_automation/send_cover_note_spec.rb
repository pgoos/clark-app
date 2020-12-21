# frozen_string_literal: true

require "spec_helper"

require "structs/plan"
require "structs/admin"
require "structs/product"
require "structs/subcompany"
require "lifters/domain/order_automation/send_cover_note"

RSpec.describe Domain::OrderAutomation::SendCoverNote do
  let(:contact_type) { "direct_agreement" }
  let(:fonds_finanz_email) { "fonds_finanz@email.org" }
  let(:quality_pool_email) { "quality_pool@email.org" }
  let(:email_sender) { class_double("EmailSender") }
  let(:plans_repository) { class_double("PlansRepository") }
  let(:documents_repository) { class_double("DocumentsRepository") }
  let(:subcompanies_repository) { class_double("SubcompaniesRepository") }
  let(:service) do
    described_class.new(
      email_sender: email_sender,
      plans_repository: plans_repository,
      documents_repository: documents_repository,
      subcompanies_repository: subcompanies_repository
    )
  end

  let(:admin) { Structs::Admin.new(first_name: "John", last_name: "Doe", email: "test@example.com") }
  let(:product) { Structs::Product.new(id: 798, plan_id: 987, state: "order_pending") }
  let(:plan) { Structs::Plan.new(id: 123, subcompany_id: 123) }
  let(:subcompany) { Structs::Subcompany.new(id: 876, order_email: "mail@example.org", contact_type: contact_type) }

  before do
    allow(plans_repository).to receive(:find).and_return(plan)
    allow(subcompanies_repository).to receive(:find).and_return(subcompany)
    allow(documents_repository).to receive(:exists_cover_note?).and_return(true)
    allow(Features).to receive(:active?).with(Features::ORDER_AUTOMATION).and_return(true)
  end

  describe "sending email" do
    context "when direct agreement is configured" do
      it "sends an email to order_email" do
        expect(email_sender).to receive(:call).with(product.id, admin, subcompany.order_email)

        service.execute(product, admin, fonds_finanz_email, quality_pool_email)
      end
    end

    context "when fonds finanz is configured" do
      let(:contact_type) { "fonds_finanz" }

      it "sends an email to fonds finanz email" do
        expect(email_sender).to receive(:call).with(product.id, admin, fonds_finanz_email)

        service.execute(product, admin, fonds_finanz_email, quality_pool_email)
      end
    end

    context "when quality pool is configured" do
      let(:contact_type) { "quality_pool" }

      it "sends an email to quality pool email" do
        expect(email_sender).to receive(:call).with(product.id, admin, quality_pool_email)

        service.execute(product, admin, fonds_finanz_email, quality_pool_email)
      end
    end
  end

  context "when contact type is undefined" do
    let(:contact_type) { "undefined" }

    it "raises an exception" do
      expect {
        service.execute(product, admin, fonds_finanz_email, quality_pool_email)
      }.to raise_error(Errors::EmailNotConfigured)
    end
  end

  context "when there is no cover note" do
    before do
      allow(documents_repository).to receive(:exists_cover_note?).and_return(false)
    end

    it "raises an exception" do
      expect {
        service.execute(product, admin, fonds_finanz_email, quality_pool_email)
      }.to raise_error(Errors::MissingCoverNote)
    end
  end

  context "when Feature flag is not active" do
    before do
      allow(Features).to receive(:active?).with(Features::ORDER_AUTOMATION).and_return(false)
    end

    it "doesn't call email_sender" do
      expect(email_sender).not_to receive(:call)

      service.execute(product, admin, fonds_finanz_email, quality_pool_email)
    end
  end
end
