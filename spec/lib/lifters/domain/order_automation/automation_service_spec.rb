# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OrderAutomation::AutomationService, :integration do
  describe "#start" do
    subject { described_class.new(product, old_product: old_product) }

    let(:product) { create(:product, :suhk_product) }
    let(:old_product) { create(:product) }

    let(:cover_note_generator_double) { instance_double(Domain::OrderAutomation::CoverNoteGenerator) }
    let(:pdf_file) { fixture_file_upload(Rails.root.join("spec", "fixtures", "dummy-mandate.pdf")) }

    before do
      allow(Domain::OrderAutomation::CoverNoteGenerator).to(
        receive(:new).and_return(double(generate_pdf: pdf_file))
      )
    end

    context "without a suhk product" do
      let(:product) { create(:product, :retirement_equity_category) }

      it "does not create cover note document" do
        allow(Features).to receive(:active?).and_return(false)
        allow(Features).to receive(:active?).with(Features::ORDER_AUTOMATION).and_return(true)

        subject.start
        expect(product.documents).to be_empty
      end
    end

    context "with a suhk product" do
      it "creates a new document when generator does not have a problem" do
        allow(Features).to receive(:active?).and_return(false)
        allow(Features).to receive(:active?).with(Features::ORDER_AUTOMATION).and_return(true)

        subject.start

        document = product.reload.documents.find { |doc| doc.document_type == DocumentType.deckungsnote }
        expect(document).to be_instance_of(Document)
      end

      it "returns when the feature switch is turned off" do
        allow(Features).to receive(:active?).and_return(false)
        subject.start
        expect(product.documents).to be_empty
      end
    end
  end
end
