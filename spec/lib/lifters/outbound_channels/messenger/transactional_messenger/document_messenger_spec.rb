# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::DocumentMessenger do
  let(:random_seed) { (rand * 100).floor + 1 }
  let(:product_id) { random_seed }
  let(:name) { "Customer Name#{random_seed}" }
  let(:content_key) { "important_documents_notification" }

  context "i18n" do
    let(:options) do
      {
        name:       name,
        product_id: product_id
      }
    end
    let(:message) { I18n.t("messenger.#{content_key}.content", options) }
    let(:cta_link) { I18n.t("messenger.#{content_key}.cta_link", options) }
    let(:cta_text) { I18n.t("messenger.#{content_key}.cta_text", options) }
    let(:cta_section) { I18n.t("messenger.#{content_key}.cta_section", options) }

    before do
      @current_locale = I18n.locale
      I18n.locale = :de
    end

    after do
      I18n.locale = @current_locale
    end

    it "should provide the message" do
      expect(message).not_to match(/translation missing/)
    end

    it "should provide the message with the name" do
      expect(message).to match(name)
    end

    it "should provide the message with the product ic" do
      expect(message).to match(product_id.to_s)
    end

    it "should provide the cta_link" do
      expected_link = "/app/manager/products/#{product_id}"
      expect(cta_link).to eq(expected_link)
    end

    it "should provide the cta_text" do
      expect(cta_text).not_to match(/translation missing/)
    end

    it "should provide the cta_section" do
      expect(cta_section).not_to match(/translation missing/)
    end
  end

  context "messenger" do
    let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }
    let(:messenger) { instance_double(messenger_class) }
    let(:mandate) { instance_double(Mandate, id: random_seed, first_name: name) }
    let(:document) do
      instance_double(
        Document,
        documentable:    product,
        documentable_id: product_id
      )
    end
    let(:product) { instance_double(Product) }

    before do
      allow(mandate).to receive(:is_a?).with(Class).and_return(false)
      allow(mandate).to receive(:is_a?).with(Mandate).and_return(true)
      allow(document).to receive(:is_a?).with(Class).and_return(false)
      allow(document).to receive(:is_a?).with(Document).and_return(true)
      allow(product).to receive(:is_a?).with(Class).and_return(false)
      allow(product).to receive(:is_a?).with(Product).and_return(true)
    end

    context "successful message building" do
      before do
        allow(messenger_class).to receive(:new).with(any_args).and_return(messenger)
        allow(messenger).to receive(:send_message)
      end

      it "should create the document notification message" do
        expect(messenger_class)
          .to receive(:new)
          .with(
            mandate,
            content_key,
            {
              name: name, # customer's first name
              product_id: product_id
            },
            kind_of(Config::Options)
          )
          .and_return(messenger)
        messenger_class.important_documents_notification(mandate, document)
      end

      it "should send the document notification message" do
        expect(messenger).to receive(:send_message)
        messenger_class.important_documents_notification(mandate, document)
      end
    end

    context "errors" do
      it "should fail, if no mandate is given" do
        expect {
          messenger_class.important_documents_notification(nil, document)
        }.to raise_error("Mandate not found!")
      end

      it "should fail, if no document is given" do
        expect {
          messenger_class.important_documents_notification(mandate, nil)
        }.to raise_error("No document given!")
      end

      it "should fail, if no product is given" do
        allow(document).to receive(:documentable).and_return("arbitrary object")
        expect {
          messenger_class.important_documents_notification(mandate, document)
        }.to raise_error("Product not found!")
      end
    end
  end
end
