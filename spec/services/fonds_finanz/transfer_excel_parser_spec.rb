# frozen_string_literal: true

require "rails_helper"
require "services/fonds_finanz/transfer_excel_fixtures"

RSpec.describe FondsFinanz::TransferExcelParser do
  include_context "transfer excel fixtures"

  subject { FondsFinanz::TransferExcelParser.new(instance_double(File)) }

  let(:random_seed) { ((rand * 30) + 1).floor }
  let(:product_number) { "product_number_#{random_seed}" }
  let(:company_name) { "company_#{random_seed}" }
  let(:first_name) { "first_name_#{random_seed}" }
  let(:last_name) { "last_name_#{random_seed}" }
  let(:date_of_birth) { "#{random_seed}.01.1980" }
  let(:date_of_acceptance) { random_seed.days.ago.strftime("%d.%m.%Y") }

  let(:accepted_row) do
    [
      "0",
      "1",
      product_number,
      company_name,
      first_name,
      last_name,
      date_of_birth,
      "7",
      "8",
      "9",
      "10",
      date_of_acceptance,
      "12",
      "", # 13
      "", # 14
      "", # 15
      "", # 16
      "", # 17
      "", # 18
      "", # 19
      "", # 20
      "", # 21
      "", # 22
      "", # 23
      "", # 24 Y
    ]
  end

  let(:excel) { double("excel file") }
  let(:rows) { [(0..14).to_a] }

  let(:set_up_sheet_headers) do
    row = rows[0]
    row[described_class::KUNDE_VORNAME_COL]                      = "Kunde Vorname" # col. E
    row[described_class::KUNDE_NACHNAME_COL]                     = "Kunde Nachname" # col. F
    row[described_class::KUNDE_GEBURTSDATUM_COL]                 = "Kunde Geburtsdatum" # col. G
    row[described_class::PRODUKT_VERSICHERUNGSSCHEIN_NUMMER_COL] = "Externe Vertragsnummer" # col. C
    row[described_class::PRODUKT_GESELLSCHAFT_COL]               = "Gesellschaft" # col. D
    row[described_class::PRODUKT_BUE_ANNAHME_DATUM_COL]          = "BUE-Annahme" # col. L
    row[described_class::PRODUKT_BUE_ABLEHNUNG_DATUM_COL]        = "BUE-Ablehnung" # col. N
    row[described_class::PRODUCT_TRANSFERRED_AWAY]               = "Vertrag wegübertragen" # col. O
    row[described_class::PRODUCT_ID_CLARK]                       = "Info Extern" # col. Y
  end

  before do
    allow(SimpleXlsxReader).to receive(:open).with(any_args).and_return(excel)
  end

  it "should not be corrupt, if headers are given" do
    expect(subject).not_to be_corrupt
  end

  it "#products_with_transfer_update should return an empty list, if the sheet is empty" do
    expect(subject.products_with_transfer_update).to eq([])
  end

  context "with data" do
    let(:bue_product) { instance_double(described_class::BueProduct) }
    let(:bue_class) { described_class::BueProduct }

    before do
      allow(bue_class).to receive(:new).with(accepted_row).and_return(bue_product)
      allow(bue_product).to receive(:transfer_state_updated?).and_return(true)
    end

    it "should include a product, if accepted" do
      rows << accepted_row
      parsed_product = subject.products_with_transfer_update.first
      expect(parsed_product).to eq(bue_product)
    end

    it "considers a different header format" do
      rows[0][described_class::PRODUCT_ID_CLARK] = "Info-Extern"
      expect(subject.corrupt?).to eq false
    end
  end
end
