# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/update_customers"

RSpec.describe N26::Constituents::Freyr::Interactors::UpdateCustomers do
  subject { described_class.new }

  let(:file_path) { "test_file.csv" }
  let(:s3_bucket) { nil }
  let(:importer) { double(perform: true) }

  before do
    allow(N26::Constituents::Freyr::Importer::Base).to receive(:new).and_return(importer)
  end

  it "initializes the importer with the right path" do
    expect(N26::Constituents::Freyr::Importer::Base).to receive(:new).with(file_path)

    subject.call(file_path, s3_bucket)
  end

  it "calls the importer to perform" do
    expect(importer).to receive(:perform)

    subject.call(file_path, s3_bucket)
  end

  context "when there is s3_bucket passed" do
    let(:s3_bucket) { "test_bucket" }
    let(:temp_file) { double(path: "temp/test_data.csv") }

    before do
      allow(Platform::S3File).to receive(:new).and_return(double(read_to_file: temp_file))
    end

    it "passes the path of the temp file to the importer" do
      expect(N26::Constituents::Freyr::Importer::Base).to receive(:new).with(temp_file.path)

      subject.call(file_path, s3_bucket)
    end
  end
end
