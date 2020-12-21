# frozen_string_literal: true

require "rails_helper"
require "services/pdf_generator/stubbed_template_shared"

RSpec.describe PdfGenerator::Generator do
  before do
    allow_any_instance_of(PDFKit).to receive(:to_pdf).and_call_original
  end

  describe ".view_instance" do
    subject { described_class.view_instance }

    it { is_expected.to be_a_kind_of(ActionView::Base) }
  end

  describe ".render" do
    subject { described_class.render(template, locals) }

    include_context "stubbed template"

    it { is_expected.to match '<p>Hello world</p>\n<p>variable_value</p>' }
  end

  describe ".base64_pdf" do
    subject { described_class.base64_pdf(template, locals) }

    include_context "stubbed template"

    it do
      expect(subject)
        .to match "data:application/pdf;base64,JVBERi0xLjQKMSAwIG9iago8PAovVGl0bGUgKP7/KQovQ3JlYXRvciAo"
    end
  end

  describe ".pdf_from_image_uploads" do
    let(:image1) { double(:image1, read: "image1") }
    let(:image2) { double(:image2, read: "image2") }
    let(:file1) { {tempfile: image1} }
    let(:file2) { {tempfile: image2} }

    it "orient images before rendering pdf" do
      expect(ImageOrienter).to receive(:call).with(image1).and_return(image1)
      expect(ImageOrienter).to receive(:call).with(image2).and_return(image2)

      described_class.pdf_from_image_uploads([file1, file2])
    end
  end
end
