# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::RetirementProductMessenger do
  describe ".retirement_product_information_requested" do
    let(:content_key) { "retirement_product_information_requested" }
    let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }
    let(:messenger) { instance_double messenger_class }
    let(:mandate) { object_double Mandate.new, id: 111, first_name: "NAME" }

    let(:retirement_product) do
      object_double(
        Retirement::Product.new,
        product_id: "PRODUCT_ID",
        category_name: "KATEGORIE",
        requested_information_str: "REQUESTED_INFORMATION"
      )
    end

    let(:options) do
      {
        name: "NAME",
        product_id: "PRODUCT_ID",
        kategorie: "KATEGORIE",
        requested_information: "REQUESTED_INFORMATION",
        brand: "Clark"
      }
    end

    describe "I18n" do
      include_context "with transactional messenger locales"

      it "provides the message" do
        expect(message).not_to match(/translation missing/)
      end

      it "provides the message with the name" do
        expect(message).to match "NAME"
      end

      it "provides the message with the category name" do
        expect(message).to match "KATEGORIE"
      end

      it "provides the message with the requested information" do
        expect(message).to match "REQUESTED_INFORMATION"
      end

      it "provides the cta_link" do
        expected_link = "/app/retirement/wizards/PRODUCT_ID/upload-documents"
        expect(cta_link).to eq expected_link
      end

      it "provides the cta_text" do
        expect(cta_text).not_to match(/translation missing/)
      end
    end

    describe "messenger" do
      before do
        allow(messenger_class).to receive(:new).with(any_args).and_return(messenger)
        allow(messenger).to receive(:send_message)
      end

      it "creates a retirement product notification message" do
        expect(messenger_class)
          .to receive(:new)
          .with(
            mandate,
            content_key,
            options,
            kind_of(Config::Options)
          )
          .and_return(messenger)
        messenger_class
          .retirement_product_information_requested(mandate, retirement_product)
      end

      it "sends the retirement product notification message" do
        expect(messenger).to receive(:send_message)
        messenger_class
          .retirement_product_information_requested(mandate, retirement_product)
      end
    end
  end
end
