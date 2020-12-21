# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Csv do
  subject {
    described_class.new(
      repository: repository,
      filename: nil,
      translation_key: nil,
      encoding: report_encoding,
      after_generate: after_generate
    )
  }

  let(:report_fields) { %w[field1 field2] }
  let(:report_values) { %w[value1 value2] }

  let(:report_data) do
    [
      Hash[report_fields.zip(report_values)]
    ]
  end

  let(:repository) do
    repo = double(:repository)
    allow(repo.class).to receive(:fields_order).and_return(report_fields)
    allow(repo).to receive(:all).and_return(report_data)
    repo
  end

  describe "Encoding" do
    let(:after_generate) { nil }
    let(:expected_csv) do
      CSV.generate do |csv|
        csv << report_fields
        csv << report_values
      end
    end

    context "when report encoding is nil" do
      let(:report_encoding) { nil }

      it "returns report" do
        expect(subject.generate_csv).to eq(expected_csv)
      end
    end

    context "when report encoding isn't nil" do
      let(:report_encoding) { "windows-1252" }

      context "when report doesn't contain unprocessable sequences" do
        it "returns report" do
          expect(subject.generate_csv).to eq(expected_csv)
        end
      end

      context "when report contains unprocessable sequences" do
        let(:report_values) { ["\u2264", "\u2264"] }

        it "replace them with default sequence" do
          report = subject.generate_csv
          expect(report).to match(/\?,\?/)
        end
      end
    end
  end

  context "called with after_generate argument" do
    let(:after_generate) { proc { } }
    let(:report_encoding) { nil }

    it "runs the after_generate block" do
      expect(after_generate).to receive(:call)
      subject.generate_csv
    end
  end
end
