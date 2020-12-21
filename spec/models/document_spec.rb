# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id                :integer          not null, primary key
#  asset             :string
#  content_type      :string
#  size              :integer
#  documentable_id   :integer
#  documentable_type :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  document_type_id  :integer
#  metadata          :jsonb
#  qualitypool_id    :integer
#

require "rails_helper"

RSpec.describe Document, type: :model do
  # Setup

  subject { document }

  let(:document) do
    document = build_stubbed(:document)
    document.documentable = build_stubbed(:user)
    document
  end

  it { is_expected.to be_valid }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"
  it_behaves_like "an event observable model"

  # State Machine
  # Scopes
  # Associations

  it { is_expected.to belong_to(:documentable) }
  it { is_expected.to belong_to(:document_type) }

  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:documentable) }
  it { is_expected.to validate_presence_of(:document_type) }

  it "must have an asset" do
    document = FactoryBot.build(:document, asset: nil)

    expect(document).not_to be_valid
    expect(document.errors[:asset]).to be_present
  end

  # Callbacks
  # Instance Methods

  describe "#name" do
    subject { document.name }

    before { allow(document).to receive(:asset).and_return(double("asset", file: "a file")) }

    it { is_expected.to eq "#{Document.model_name.human} ##{document.id}" }
  end

  describe "#file_name" do
    context "with asset" do
      let(:document) { build_stubbed(:document) }

      it do
        expect(document.file_name).to eq "mandate.pdf"
      end

      context "without asset" do
        let(:document) { build_stubbed(:document, asset: nil) }

        it do
          expect(document.file_name).to eq "Upload #{document.id}"
        end
      end

      context "when document type is related to customer upload" do
        let(:document) { build_stubbed(:document, document_type: document_type) }
        let(:document_type) { DocumentType.situation }

        it do
          expect(document.file_name).to eq document_type.name
        end
      end
    end
  end

  describe "#infer_mandate" do
    # This method should be maintained in a best effort to infer the mandate from the document.
    let(:mandate) { FactoryBot.build_stubbed(:mandate) }

    it "should return the mandate, if it is the documentable" do
      document = Document.new(documentable: mandate)
      expect(document.infer_mandate).to eq(mandate)
    end

    it "should not return the mandate, if it is not the documentable" do
      document = Document.new(documentable: Company.new)
      expect(document.infer_mandate).to be_nil
    end

    it "should delegate to the documentable's mandate, if possible" do
      product = Product.new(mandate: mandate)
      document = Document.new(documentable: product)
      expect(document.infer_mandate).to eq(mandate)
    end
  end

  context "local copy" do
    it "provides a path to local copy" do
      path = document.provide_local_copy
      expect(path).to eq(Rails.root.join("tmp", "document_#{document.id}_type_#{document.document_type_id}"))
    end

    it "provides a local copy" do
      path = document.provide_local_copy
      expect(File.exist?(path)).to be(true)
    end

    it "contains the same content in the local copy" do
      path = document.provide_local_copy
      content = File.read(path, mode: "rb")
      expect(content).to eq(document.asset.read)
    end

    it "will not fail if tried to create the local copy multiple times" do
      path = document.provide_local_copy
      expect(File).not_to receive(:open)
      expect(document.provide_local_copy).to eq(path)
    end

    it "removes the local copy" do
      path = document.provide_local_copy
      document.remove_local_copy
      expect(File.exist?(path)).to be(false)
    end

    it "removes the local copy only if there" do
      document.provide_local_copy
      document.remove_local_copy
      expect {
        document.remove_local_copy
      }.not_to raise_error
    end
  end

  describe "#on_local_copy" do
    context "when block given" do
      it "will call provide_locale_copy" do
        expect(document).to receive(:provide_local_copy).once
        document.on_local_copy { |file_path| puts(file_path) }
      end

      it "will call remove_local_copy" do
        expect(document).to receive(:remove_local_copy)
        document.on_local_copy { |file_path| puts(file_path) }
      end
    end

    context "when No block given" do
      it "will NOT call provide_locale_copy" do
        expect(document).not_to receive(:provide_locale_copy)
        document.on_local_copy
      end

      it "will NOT call remove_local_copy" do
        expect(document).not_to receive(:remove_local_copy)
        document.on_local_copy
      end
    end
  end

  describe ".by_insign_session_id" do
    it "returns documents with specified insign session id" do
      create :shallow_document, metadata: { insign: { session_id: "FOO" } }
      doc = create :shallow_document, metadata: { insign: { session_id: "BAR" } }
      create :shallow_document

      expect(described_class.by_insign_session_id("BAR")).to eq [doc]
    end
  end

  describe "#insign_signing_process_finished?" do
    subject { document.insign_signing_process_finished? }

    let(:document) { Document.new }

    context "with completed value metadata" do
      context "when its set to false" do
        before { document.insign = { "completed" => false } }

        it { is_expected.to eq false }
      end

      context "when its set to true" do
        before { document.insign = { "completed" => true } }

        it { is_expected.to eq true }
      end
    end

    context "with empty metadata" do
      it { is_expected.to eq false }
    end
  end

  describe "#metadata" do
    subject(:document) do
      build(
        :document,
        :shallow,
        metadata: {
          "info" => "TEST",
          "created" => "2017-07-01T00:00:00.000+00:00",
          "changed" => "2017-05-01T00:00:00.000+00:00"
        }
      )
    end

    it "casts \"changed\" key value into DateTime" do
      expect(document.metadata["changed"]).to be_a ActiveSupport::TimeWithZone
    end

    it "casts \"created\" key value into DateTime" do
      expect(document.metadata["created"]).to be_a ActiveSupport::TimeWithZone
    end

    it "does not cast already casted value" do
      document.metadata
      expect { document.metadata }.not_to raise_error
    end
  end

  describe ".allowed_to_customer", :integration do
    let!(:document_types) do
      [
        create(:document_type, :visible_to_prospect_customer),
        create(:document_type, :visible_to_mandate_customer)
      ]
    end

    let!(:documents) do
      [
        create(:document, document_type: document_types[0]),
        create(:document, document_type: document_types[1])
      ]
    end

    it "returns document types based on customer state" do
      expect(described_class.allowed_to_customer("prospect")).to include(documents[0])
      expect(described_class.allowed_to_customer("mandate_customer")).to include(documents[1])
      expect(described_class.allowed_to_customer(nil)).to include(documents[1])
    end
  end

  describe "#send_to_salesforce" do
    it "sends opportunity to salesforce if document type POLICY and product exists" do
      product = create(:product)
      opportunity = create(:opportunity, :completed, sold_product_id: product.id)
      expect(Opportunity).to receive(:send_to_salesforce).with("sold", opportunity)
      create(:document, documentable: product, document_type: DocumentType.policy)
    end

    it "sends opportunity to salesforce if document type product_application_for_signing" do
      product = create(:product)
      opportunity = create(:opportunity, :completed, old_product_id: product.id)
      expect(Opportunity).to receive(:send_to_salesforce).with("offer_accepted", opportunity)
      document_type = create(:document_type, key: "product_application_for_signing")
      create(:document, documentable: opportunity, document_type: document_type, insign: { "completed" => true })
    end
  end
end
