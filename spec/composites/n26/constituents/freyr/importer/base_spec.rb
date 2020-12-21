# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/importer/base"

RSpec.describe N26::Constituents::Freyr::Importer::Base do
  subject { described_class.new(csv_path) }

  let(:csv_path) { "file_name.csv" }
  let(:mandate_infos_to_update) {
    [
      { mandate_id: 99, email: Faker::Internet.email, phone_number: "+49111111" }
    ]
  }
  let(:parser) { double(N26::Constituents::Freyr::Importer::Parsers::Csv) }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(N26::Logger).to receive(:info).and_return(true)
    allow(SmarterCSV).to receive(:process).and_yield(mandate_infos_to_update)
    allow(N26::Constituents::Freyr::Repositories::CustomerRepository)
      .to receive(:new).and_return(double(customer_ids_already_imported: []))
  end

  it "builds parser with the file path" do
    expect(N26::Constituents::Freyr::Importer::Parsers::Csv).to receive(:new).with(csv_path)
    subject
  end

  context "when the entry is not updated" do
    let(:entry) { double(save: true) }

    before do
      allow(::N26::Constituents::Freyr::Importer::Entry).to receive(:new).and_return(entry)
    end

    it "builds entry" do
      expect(::N26::Constituents::Freyr::Importer::Entry).to receive(:new)
      subject.perform
    end

    it "initiates the save of entry" do
      expect(entry).to receive(:save)

      subject.perform
    end
  end

  context "when the entry is updated already" do
    it "doesn't initiate the build of entry" do
      allow(N26::Constituents::Freyr::Repositories::CustomerRepository)
        .to receive(:new).and_return(double(customer_ids_already_imported: [mandate_infos_to_update[0][:mandate_id]]))

      expect(::N26::Constituents::Freyr::Importer::Entry).not_to receive(:new)

      subject.perform
    end
  end

  context "when the file doesn't exists" do
    before do
      allow(File).to receive(:exist?).and_return(false)
    end

    it "raises error" do
      expect {
        subject
      }.to raise_error(ArgumentError, "File doesn't exist")
    end
  end
end
