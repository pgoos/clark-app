# frozen_string_literal: true

RSpec.shared_context "transfer excel fixtures" do
  let(:random_seed) { rand(1..30) } # this range is required due to the dates that we test
  let(:product_clark_id) { random_seed }
  let(:product_number) { "product_number_#{random_seed}" }
  let(:company_name) { "company_#{random_seed}" }
  let(:first_name) { "first_name_#{random_seed}" }
  let(:last_name) { "last_name_#{random_seed}" }
  let(:date_of_birth) { "#{random_seed}.10.1980" }
  let(:birthdate_parsed) { Date.strptime(date_of_birth, "%d.%m.%Y") }
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
      product_clark_id.to_s, # 24 Y
    ]
  end
  let(:row) { accepted_row }

  let(:excel) { double("excel file") }
  let(:rows) { [(0..14).to_a] }

  let(:set_up_sheet_headers) do
    clz                                                  = FondsFinanz::TransferExcelParser
    rows[0][clz::KUNDE_VORNAME_COL]                      = "Kunde Vorname" # col. E
    rows[0][clz::KUNDE_NACHNAME_COL]                     = "Kunde Nachname" # col. F
    rows[0][clz::KUNDE_GEBURTSDATUM_COL]                 = "Kunde Geburtsdatum" # col. G
    rows[0][clz::PRODUKT_VERSICHERUNGSSCHEIN_NUMMER_COL] = "Externe Vertragsnummer" # col. C
    rows[0][clz::PRODUKT_GESELLSCHAFT_COL]               = "Gesellschaft" # col. D
    rows[0][clz::PRODUKT_BUE_ANNAHME_DATUM_COL]          = "BUE-Annahme" # col. L
    rows[0][clz::PRODUKT_BUE_ABLEHNUNG_DATUM_COL]        = "BUE-Ablehnung" # col. N
    rows[0][clz::PRODUCT_TRANSFERRED_AWAY]               = "Vertrag wegübertragen" # col. O
    rows[0][clz::PRODUCT_ID_CLARK]                       = "Info Extern" # col. Y
  end

  before do
    allow(excel).to receive_message_chain(:sheets, :first, :rows).and_return(rows)
    set_up_sheet_headers
  end
end
