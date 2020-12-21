# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Documents::ConsultantNotifier do
  include Rails.application.routes.url_helpers

  let(:message) { described_class::Message.new(document) }
  let(:positive_integer) { (rand * 100).round + 2 }
  let(:document) do
    instance_double(
      Document,
      documentable_type: "Product",
      documentable_id:   positive_integer
    )
  end
  let(:doc_type_ids) do
    i = positive_integer
    id_mapping = described_class::NOTIFIABLE_DOCUMENT_TYPES.map do |doc_name|
      i += 1
      [doc_name, i]
    end
    id_mapping.to_h.freeze
  end
  let(:unknown_doc_type_id) { 1 } # positive_integer is at least 2

  before do
    allow(described_class).to receive(:document_type_ids).and_return(doc_type_ids.values)
    default_url_options[:host] = ActionMailer::Base.default_url_options[:host]
  end

  it "responds to after_create" do
    expect(described_class).to respond_to(:after_create).with(1).argument
  end

  context "sending" do
    let(:from) { Settings.emails.service }
    let(:to) { Settings.emails.service }

    described_class::NOTIFIABLE_DOCUMENT_TYPES.each do |doc_type_key|
      it "should notify service@clark.de, if the doc type is #{doc_type_key}" do
        document_type_id = doc_type_ids[doc_type_key]
        allow(document).to receive(:document_type_id).and_return(document_type_id)

        expect_any_instance_of(OutboundChannels::Mailer)
          .to receive(:send_plain_text)
          .with(from, to, described_class::Message)

        described_class.after_create(document)
      end
    end

    it "should create the message" do
      document_type_id = doc_type_ids["nachtrag"]
      allow(document).to receive(:document_type_id).and_return(document_type_id)

      message = instance_double(described_class::Message)
      expect_any_instance_of(OutboundChannels::Mailer)
        .to receive(:send_plain_text)
        .with(String, String, message)
      expect(described_class::Message)
        .to receive(:new)
        .with(document)
        .and_return(message)

      described_class.after_create(document)
    end

    it "should not send for arbitrary document types" do
      allow(document).to receive(:document_type_id).and_return(unknown_doc_type_id)

      expect_any_instance_of(OutboundChannels::Mailer).not_to receive(:send_plain_text)

      described_class.after_create(document)
    end
  end

  context ".document_type_ids" do
    before do
      allow(described_class).to receive(:document_type_ids).and_call_original
    end

    it "memoizes the method value correctly" do
      first_document_type = described_class::NOTIFIABLE_DOCUMENT_TYPES.first
      described_class.flush_cache

      allow(Domain::MasterData::DocumentTypes).to receive(:find_by_key)
      described_class.document_type_ids
      described_class.document_type_ids
      described_class.document_type_ids

      expect(Domain::MasterData::DocumentTypes).to have_received(:find_by_key).with(first_document_type).once
    end
  end

  context "message" do
    let(:doc_type_name) { "Kündigungsbestätigung" }
    let(:expected_subject) do
      I18n.t(
        "manager.products.show.documents.notifications.consultants.subject",
        model_name: Product.model_name.human,
        id:         positive_integer
      )
    end
    let(:expected_body) do
      url = url_for(
        action:     "show",
        controller: "admin/products",
        only_path:  false,
        id:         positive_integer,
        locale:     :de
      )
      I18n.t(
        "manager.products.show.documents.notifications.consultants.body",
        model_link: url,
        doc_type_name: doc_type_name
      )
    end

    before do
      @remembered_locale = I18n.locale
      I18n.locale = :de
      allow(document).to receive_message_chain("document_type.name").and_return doc_type_name
    end

    after do
      I18n.locale = @remembered_locale
    end

    it "should internationalize the subject" do
      expect(expected_subject).not_to match("translation missing")
    end

    it "shows the subject as expected" do
      expect(message.subject).to eq(expected_subject)
    end

    it "should internationalize the body" do
      expect(expected_body).not_to match("translation missing")
    end

    it "shows the expected body" do
      expect(message.body).to eq(expected_body)
    end
  end
end
