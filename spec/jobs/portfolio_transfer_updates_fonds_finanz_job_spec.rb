# frozen_string_literal: true

require "rails_helper"

RSpec.describe PortfolioTransferUpdatesFondsFinanzJob, type: :job do
  let(:excel_document) { instance_double(Document) }
  let(:excel_parser) { instance_double(FondsFinanz::TransferExcelParser) }
  let(:excel_id) { 1 + (rand * 100).round }
  let(:excel_id_does_not_exist) { 100 + excel_id }

  let(:product_1) { instance_double(Product, id: 1) }
  let(:bue_product_1) do
    instance_double(
      FondsFinanz::TransferExcelParser::BueProduct,
      product:    product_1,
      number:     "number_1",
      company:    "Company 1",
      first_name: "FirstName1",
      last_name:  "LastName1",
      birthdate:  Time.zone.today.advance(years: -20)
    )
  end

  let(:product_2) { instance_double(Product, id: 2) }
  let(:bue_product_2) do
    instance_double(
      FondsFinanz::TransferExcelParser::BueProduct,
      product:    product_2,
      number:     "number_2",
      company:    "Company 2",
      first_name: "FirstName2",
      last_name:  "LastName2",
      birthdate:  Time.zone.today.advance(years: -30)
    )
  end

  it { is_expected.to be_a(ClarkJob) }

  before do
    @reset_locale = I18n.locale
    I18n.locale   = :de

    allow(FondsFinanz::TransferExcelParser).to receive(:load_excel_document)
      .with(excel_id).and_return(excel_document)
    raw_file_path = "./tmp/sample/path/to/file"
    allow(excel_document).to receive(:provide_local_copy).and_return(raw_file_path)
    allow(excel_document).to receive(:remove_local_copy).and_return(raw_file_path)

    allow(FondsFinanz::TransferExcelParser).to receive(:load_excel_document)
      .with(excel_id_does_not_exist).and_raise("Excel not found: '#{excel_id_does_not_exist}'")

    allow(FondsFinanz::TransferExcelParser).to receive(:new)
      .with(raw_file_path).and_return(excel_parser)
    allow(excel_parser).to receive(:corrupt?).and_return(false)

    allow(bue_product_1).to receive(:perform_transfer_update!).and_return("take_under_management")
    allow(bue_product_2).to receive(:perform_transfer_update!).and_return("take_under_management")
    allow(AsyncJobLog).to receive(:create!)
  end

  after do
    I18n.locale = @reset_locale
  end

  it "does nothing with an empty excel" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([])
    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :info,
      message:    {"summary" => expected_summary(0, 0, 0, 0)},
      topic:      excel_document,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "removes the local copy after processing" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([])
    expect(excel_document).to receive(:remove_local_copy)
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "if one product is given in the excel the summary shows one processed entity" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([bue_product_1])
    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :info,
      message:    {"summary" => expected_summary(1, 0, 0, 0)},
      topic:      excel_document,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "updates one product, if one product is given in the excel" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([bue_product_1])
    expect(bue_product_1).to receive(:perform_transfer_update!)
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "if one product is given in the excel the summary shows one processed entity" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([
      bue_product_1, bue_product_2
    ])
    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :info,
      message:    {"summary" => expected_summary(2, 0, 0, 0)},
      topic:      excel_document,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "updates all products, if more than one product is given in the excel" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([
      bue_product_1, bue_product_2
    ])
    expect(bue_product_1).to receive(:perform_transfer_update!)
    expect(bue_product_2).to receive(:perform_transfer_update!)
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "fails if the excel is corrupt" do
    allow(excel_parser).to receive(:corrupt?).and_return(true)
    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :error,
      message:    {"summary" => "The excel file is corrupt!"},
      topic:      excel_document,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "fails if no excel is found" do
    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :error,
      message:    {"summary" => "Excel not found: '#{excel_id_does_not_exist}'"},
      topic:      nil,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id_does_not_exist)
  end

  it "fails if no id to look up the excel is given" do
    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :error,
      message:    {"summary" => "No excel document id given!"},
      topic:      nil,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )
    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: nil)
  end

  it "logs an error for every failed product" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([
      bue_product_1, bue_product_2
    ])
    error1 = "Product 1 failed"
    allow(bue_product_1).to receive(:perform_transfer_update!).and_raise(error1)
    error2 = "Product 2 failed"
    allow(bue_product_2).to receive(:perform_transfer_update!).and_raise(error2)

    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :error,
      message:    {"product" => 1, "error" => error1, "backtrace" => String, "mandate_info" => Hash},
      topic:      product_1,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )

    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :error,
      message:    {"product" => 2, "error" => error2, "backtrace" => String, "mandate_info" => Hash},
      topic:      product_2,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )

    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "logs an error summary" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([
      bue_product_1, bue_product_2
    ])
    allow(bue_product_1).to receive(:perform_transfer_update!).and_raise
    allow(bue_product_2).to receive(:perform_transfer_update!).and_raise

    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :error,
      message:    {"summary" => expected_summary(0, 0, 0, 2)},
      topic:      excel_document,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )

    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "logs warnings for missing products" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([
      bue_product_1, bue_product_2
    ])
    allow(bue_product_2).to receive(:perform_transfer_update!).and_return("not_found")

    exp_message = "Produkt '#{bue_product_2.number}' (#{bue_product_2.company}) nicht gefunden!"
    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :warn,
      message:    {"warning" => exp_message, "mandate_info" => Hash},
      topic:      nil,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )

    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :info,
      message:    {"summary" => expected_summary(1, 0, 1, 0)},
      topic:      excel_document,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )

    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  it "shows a denied products count in the summary" do
    allow(excel_parser).to receive(:products_with_transfer_update).and_return([
      bue_product_1, bue_product_2
    ])
    allow(bue_product_2).to receive(:perform_transfer_update!).and_return("deny_takeover")

    expect(AsyncJobLog).to receive(:create!).with(
      job_id:     String,
      severity:   :info,
      message:    {"summary" => expected_summary(1, 1, 0, 0)},
      topic:      excel_document,
      queue_name: "portfolio_transfer",
      job_name:   PortfolioTransferUpdatesFondsFinanzJob.name
    )

    PortfolioTransferUpdatesFondsFinanzJob.perform_now(excel_id: excel_id)
  end

  def expected_summary(successful, denied, missing, errors)
    <<EOT
Statistik:
#{successful} Produkt(e) in Verwaltung genommen
#{denied} Produkt(e) abgelehnt
#{missing} Produkt(e) nicht gefunden
#{errors} Produkt(e) verursacht(en) Fehler bei der Verarbeitung
#{successful + denied + missing + errors} Tabellenzeilen wurden verarbeitet
EOT
  end

end
