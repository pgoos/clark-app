# frozen_string_literal: true

require "rails_helper"
require "composites/home24/exporter/builders/csv"
require "composites/home24/exporter/builders/zip"

RSpec.describe Home24::Exporter::Builders::Zip do
  subject { described_class.new(file_name) }

  let(:file_name) { "test.zip" }
  let(:csv_file_name) { "test.csv" }
  let(:csv_content) { "First Name;Last Name\nTestName;TestLastname" }
  let(:files_to_put) { [Home24::Exporter::Builders::Csv::File.new(csv_file_name, csv_content)] }

  describe "#generate" do
    let(:mocked_zip_file) { double }
    let(:mocked_csv_file) { double(puts: true) }

    before do
      allow(::Zip::File).to receive(:open).and_yield(mocked_zip_file)
      allow(mocked_zip_file).to receive(:get_output_stream).and_yield(mocked_csv_file)
    end

    it "creates zip file with right parameters" do
      expect(::Zip::File)
        .to receive(:open).with("#{Home24::Exporter::Builders::Zip::TMP_DIR}/#{file_name}", ::Zip::File::CREATE)
                          .and_yield(mocked_zip_file)

      subject.generate(files_to_put)
    end

    it "creates csv file with the right name" do
      expect(mocked_zip_file).to receive(:get_output_stream).with(files_to_put[0].name)

      subject.generate(files_to_put)
    end

    it "creates csv file with the right content" do
      expect(mocked_csv_file).to receive(:puts).with(files_to_put[0].content)

      subject.generate(files_to_put)
    end
  end
end
