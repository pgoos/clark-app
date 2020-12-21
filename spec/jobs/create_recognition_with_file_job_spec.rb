# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateRecognitionWithFileJob, type: :job do
  let(:asset)  { Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "assets", "mandate.pdf")) }
  let(:object) { double("Aws::S3", content_type: "application/pdf") }
  let(:s3_file_double) { instance_double(Platform::S3File, read_to_file: asset) }

  context "with valid ocr_recognition" do
    before do
      allow(Platform::S3File).to receive(:new).and_return(s3_file_double)
    end

    it "calls the lifter correctly" do
      expect {
        subject.perform("new_policy.pdf")
      }.to change(OCR::Recognition, :count).by(1)

      recognition = OCR::Recognition.last
      expect(recognition.document).to be_present
      expect(recognition.document.asset).to be_present
    end
  end
end
