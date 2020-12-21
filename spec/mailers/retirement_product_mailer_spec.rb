# frozen_string_literal: true

require "rails_helper"

RSpec.describe RetirementProductMailer, :integration, type: :mailer do
  let!(:offer) { create :offer, mandate: mandate, opportunity: opportunity }
  let!(:mandate) { create :mandate, user: user, state: :created }
  let(:user) { create :user, email: email, subscriber: true }
  let(:email) { "whitfielddiffie@gmail.com" }
  let(:product) { create :retirement_state_product }
  let(:opportunity) { build(:opportunity, category: category) }
  let(:category) { build(:category) }
  let(:document) { offer }

  describe "#retirement_product_analysed" do
    let(:mail) { RetirementProductMailer.retirement_product_analysed(mandate, product) }
    let(:document_type) { DocumentType.retirement_product_analysed }

    it "stores a message object upon delivery" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    end

    include_examples "checks mail rendering"
    it_behaves_like "stores a message object upon delivery", "RetirementProductMailer#retirement_product_analysed", "retirement_product_mailer", "retirement_product_analysed"
  end

  describe "#information_required" do
    let(:mail) { RetirementProductMailer.information_required(mandate, product) }
    let(:document) { product }
    let(:document_type) { DocumentType.information_required }

    it "stores a message object upon delivery" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    end

    include_examples "checks mail rendering"
    it_behaves_like "stores a message object upon delivery", "RetirementProductMailer#information_required", "retirement_product_mailer", "information_required"
  end
end
