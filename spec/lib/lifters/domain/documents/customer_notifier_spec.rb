# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Documents::CustomerNotifier do
  let(:positive_integer) { (rand * 100).round + 2 }
  let(:document) do
    instance_double(
      Document,
      documentable_type: "Product",
      documentable_id:   positive_integer,
      documentable: nil,
      skip_push_notification: false,
      infer_mandate:     mandate
    )
  end
  let(:mandate) { instance_double(Mandate, owner_ident: "clark") }
  let(:mail) { n_double("mail") }
  let(:messenger) { OutboundChannels::Messenger::TransactionalMessenger }
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
    allow(DocumentMailer)
      .to receive(:important_documents_notification).with(mandate, document).and_return(mail)
    allow(mail).to receive(:deliver_now)
    allow(messenger).to receive(:important_documents_notification)
  end

  it "should not try to test the wrong id" do
    expect(doc_type_ids.values).not_to include(unknown_doc_type_id)
  end

  # rubocop:disable RSpec/PredicateMatcher
  context "#drop?" do
    it "drops for arbitrary document types" do
      allow(document).to receive(:document_type_id).and_return(unknown_doc_type_id)
      expect(described_class.drop?(document)).to be_truthy
    end

    it "drops for offered products" do
      product = build_stubbed(:product, :offered)
      allow(document).to receive(:documentable).and_return(product)
      expect(described_class.drop?(document)).to be_truthy
    end

    it "drops for if document has skip_push_notification sets to true" do
      allow(document).to receive(:skip_push_notification).and_return(true)
      document_type_id = described_class.document_type_ids.first
      allow(document).to receive(:document_type_id).and_return(document_type_id)
      expect(described_class).to be_drop(document)
    end

    context "matching doc type" do
      before do
        document_type_id = described_class.document_type_ids.first
        allow(document).to receive(:document_type_id).and_return(document_type_id)
      end

      it "does not drop for matching document types" do
        expect(described_class.drop?(document)).to be_falsey
      end

      it "drops if the documentable is not a product" do
        allow(document).to receive(:documentable_type).and_return("DifferentModel")
        expect(described_class.drop?(document)).to be_truthy
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  it "responds to after_create" do
    expect(described_class).to respond_to(:after_create).with(1).argument
  end

  it "should raise an exception, if no mandate can be inferred" do
    allow(document).to receive(:infer_mandate).and_return(nil)
    document_type_id = doc_type_ids["POLICY"]
    allow(document).to receive(:document_type_id).and_return(document_type_id)

    expect {
      described_class.after_create(document)
    }.to raise_error("no mandate found")
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

      expect(Domain::MasterData::DocumentTypes).to \
        have_received(:find_by_key).with(first_document_type).once
    end
  end

  context "mail" do
    described_class::NOTIFIABLE_DOCUMENT_TYPES.each do |doc_type_method_name|
      it "should notify service@clark.de, if the doc type is #{doc_type_method_name}" do
        document_type_id = doc_type_ids[doc_type_method_name]
        allow(document).to receive(:document_type_id).and_return(document_type_id)

        expect(DocumentMailer)
          .to receive(:important_documents_notification)
          .with(mandate, document)
          .and_return(mail)
        expect(mail).to receive(:deliver_now)

        described_class.after_create(document)
      end
    end

    it "should not send for arbitrary document types" do
      allow(document).to receive(:document_type_id).and_return(unknown_doc_type_id)

      expect(DocumentMailer).not_to receive(:important_documents_notification)

      described_class.after_create(document)
    end

    it "should also send a message to n26 customers" do
      allow(mandate).to receive(:owner_ident).and_return("n26")
      document_type_id = described_class.document_type_ids.first

      allow(document).to receive(:document_type_id).and_return(document_type_id)

      expect(DocumentMailer)
        .to receive(:important_documents_notification)
        .with(mandate, document)
        .and_return(mail)
      expect(mail).to receive(:deliver_now)

      described_class.after_create(document)
    end
  end

  context "messenger" do
    described_class::NOTIFIABLE_DOCUMENT_TYPES.each do |doc_type_method_name|
      it "should notify service@clark.de, if the doc type is #{doc_type_method_name}" do
        document_type_id = doc_type_ids[doc_type_method_name]
        allow(document).to receive(:document_type_id).and_return(document_type_id)

        expect(messenger)
          .to receive(:important_documents_notification)
          .with(mandate, document)

        described_class.after_create(document)
      end
    end

    context "when an exception is raised" do
      before do
        document_type_id = described_class.document_type_ids.first
        allow(document).to receive(:document_type_id).and_return(document_type_id)
        allow(messenger).to receive(:important_documents_notification).and_raise(StandardError)
      end

      it "should send a Raven" do
        expect(Raven).to receive(:capture_exception).and_call_original

        described_class.after_create(document)
      end

      it "should log the error" do
        expect(Rails.logger).to receive(:error)

        described_class.after_create(document)
      end
    end

    it "should not send for arbitrary document types" do
      allow(document).to receive(:document_type_id).and_return(unknown_doc_type_id)

      expect(messenger).not_to receive(:important_documents_notification)

      described_class.after_create(document)
    end

    it "should not try to send a message to n26 customers" do
      allow(mandate).to receive(:owner_ident).and_return("n26")
      document_type_id = doc_type_ids["nachtrag"]
      allow(document).to receive(:document_type_id).and_return(document_type_id)

      expect(messenger)
        .not_to receive(:important_documents_notification)
        .with(mandate, document)

      described_class.after_create(document)
    end
  end
end
