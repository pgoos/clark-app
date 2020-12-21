# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/importer/parsers/csv"

RSpec.describe N26::Constituents::Freyr::Importer::Parsers::Csv do
  subject { described_class.new(file_path) }

  let(:file_path) { "test.csv" }
  let(:mandate_info_to_update) { { mandate_id: 99, email: Faker::Internet.email, phone_number: "+(49)12311111" } }

  describe "#parse" do
    it "initiates parsing through SmarterCSV with right parameters" do
      allow(SmarterCSV).to receive(:process).and_return(true)

      expect(SmarterCSV).to receive(:process).with(file_path, hash_including(:col_sep, :chunk_size, :file_encoding))

      subject.parse
    end

    it "yields with the chunk from csv file" do
      csv_file = create_csv_file

      parser = described_class.new(csv_file.path)

      expect { |b|
        parser.parse(&b)
      }.to yield_with_args([mandate_info_to_update])
    end
  end

  def create_csv_file
    Tempfile.new("test.csv").tap do |tempfile|
      IO.binwrite(tempfile, csv_content)
    end
  end

  def csv_content
    <<~CSV_CONTENT
      mandate_id,email,phone_number
      #{mandate_info_to_update[:mandate_id]},#{mandate_info_to_update[:email]},#{mandate_info_to_update[:phone_number]}
    CSV_CONTENT
  end
end
