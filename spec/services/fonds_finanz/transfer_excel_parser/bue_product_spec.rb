# frozen_string_literal: true

require "rails_helper"
require "services/fonds_finanz/transfer_excel_fixtures"

RSpec.describe FondsFinanz::TransferExcelParser::BueProduct do
  include_context "transfer excel fixtures"
  it "include NameMatcher module" do
    expect(described_class.included_modules).to include(FondsFinanz::NameMatcher)
  end

  let(:mandate) do
    instance_double(
      Mandate,
      first_name: first_name,
      last_name: last_name,
      birthdate: Date.strptime(date_of_birth, "%d.%m.%Y").noon.in_time_zone
    )
  end
  let(:product) do
    instance_double(
      Product,
      mandate: mandate,
      takeover_requested?: true,
      termination_pending?: false,
      terminated?: false
    )
  end
  let(:event_double) { instance_double(BusinessEvent) }

  before do
    allow(product).to receive_message_chain(:business_events, :where, :last)
      .and_return(event_double)
    allow(mandate).to receive(:accepted?).and_return(true)
    allow(Mandate).to receive(:where).with(any_args).and_return([])
  end

  context "common to all bue_product instances" do
    let(:bue_product) { described_class.new(accepted_row) }

    it "returns the clark product id" do
      expect(bue_product.product_clark_id).to eq(product_clark_id)
    end

    it "returns the product number" do
      expect(bue_product.number).to eq(product_number)
    end

    it "returns the company's name" do
      expect(bue_product.company).to eq(company_name)
    end

    it "returns the first name" do
      expect(bue_product.first_name).to eq(first_name)
    end

    it "returns the last name" do
      expect(bue_product.last_name).to eq(last_name)
    end

    it "returns the date of birth" do
      expected_date = Date.strptime(date_of_birth, "%d.%m.%Y")
      expect(bue_product.birthdate).to eq(expected_date)
    end

    context "no product" do
      let(:bu_product) { described_class.new(accepted_row) }

      it "should return 'not_found', if there is no product" do
        expect(bu_product.perform_transfer_update!).to eq("not_found")
      end

      it "should have a transfer state update, if there is no product" do
        expect(bu_product).to be_transfer_state_updated
      end

      it "should not have a transfer update, if the product is not found but the mandate is revoked" do
        expect(Mandate).to receive(:where)
          .with(first_name: first_name, last_name: last_name)
          .and_return([mandate])
        allow(mandate).to receive(:accepted?).and_return(false)
        expect(bu_product).not_to be_transfer_state_updated
      end

      it "should have a transfer update, if the product is not found and more than one mandate is found" do
        allow(Mandate).to receive(:where)
          .with(first_name: first_name, last_name: last_name)
          .and_return([mandate, mandate])
        allow(mandate).to receive(:accepted?).and_return(false)
        expect(bu_product).to be_transfer_state_updated
      end
    end
  end

  context "acceptable product" do
    let(:bue_product) { described_class.new(accepted_row) }

    before do
      arel_double = n_double("arel_double")
      allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
      allow(arel_double)
        .to receive(:find_by)
        .with(id: product_clark_id)
        .and_return(product)
    end

    it "returns the date of acceptance" do
      expected_date = Date.strptime(date_of_acceptance, "%d.%m.%Y")
      expect(bue_product.accepted_date).to eq(expected_date)
    end

    it "returns the db product" do
      expect(bue_product.product).to eq(product)
    end

    it "returns the mandate" do
      expect(bue_product.mandate).to eq(mandate)
    end

    it "has a portfolio transfer state update" do
      expect(bue_product).to be_transfer_state_updated
    end

    it "returns the product message take_under_management!" do
      expect(bue_product.product_message).to eq(:take_under_management!)
    end

    it "calls the product message" do
      expect(product).to receive(:take_under_management!)
      allow(event_double).to receive(:update_attributes!)
      bue_product.perform_transfer_update!
    end

    it "updates the business event" do
      allow(product).to receive(:take_under_management!)
      parsed_date = Date.strptime(date_of_acceptance, "%d.%m.%Y")
      expect(event_double).to receive(:update_attributes!).with(created_at: parsed_date)
      bue_product.perform_transfer_update!
    end

    it "has no update, if already under management" do
      expect(product).to receive(:takeover_requested?).and_return(false)
      expect(bue_product).not_to be_transfer_state_updated
    end

    it "has no update, if the customer is not accepted" do
      allow(mandate).to receive(:accepted?).and_return(false)
      expect(bue_product).not_to be_transfer_state_updated
    end
  end

  context "product without update" do
    before do
      arel_double = n_double("arel_double")
      allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
      allow(arel_double)
        .to receive(:find_by)
        .with(id: product_clark_id)
        .and_return(product)
    end

    it "does not have a portfolio transfer state update" do
      row_without_update         = accepted_row
      col_id                     = FondsFinanz::TransferExcelParser::PRODUKT_BUE_ANNAHME_DATUM_COL
      row_without_update[col_id] = ""
      bue_product = described_class.new(row_without_update)
      expect(bue_product).not_to be_transfer_state_updated
    end

    it "does not have a transfer update if it is termination pending" do
      allow(product).to receive(:termination_pending?).and_return(true)
      bue_product = described_class.new(accepted_row)
      expect(bue_product).not_to be_transfer_state_updated
    end

    it "does not have a transfer update if it is terminated" do
      allow(product).to receive(:terminated?).and_return(true)
      bue_product = described_class.new(accepted_row)
      expect(bue_product).not_to be_transfer_state_updated
    end
  end

  context "product without number (sold by us?)" do
    let(:bue_product) do
      row_no_nr                                                                           = accepted_row
      row_no_nr[FondsFinanz::TransferExcelParser::PRODUKT_VERSICHERUNGSSCHEIN_NUMMER_COL] = ""
      described_class.new(row_no_nr)
    end

    it "does not have a portfolio transfer state update" do
      expect(bue_product).not_to be_transfer_state_updated
    end
  end

  context "denied product" do
    let(:bue_product) { described_class.new(denied_row) }
    let(:date_of_denial) { random_seed.days.ago.advance(days: 1).strftime("%d.%m.%Y") }
    let(:denied_row) do
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
        date_of_denial,
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

    before do
      arel_double = n_double("arel_double")
      allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
      allow(arel_double)
        .to receive(:find_by)
        .with(id: product_clark_id)
        .and_return(product)
    end

    it "has no update too, if already in target state" do
      allow(product).to receive(:takeover_requested?).and_return(false)
      allow(product).to receive(:under_management?).and_return(false)
      allow(product).to receive(:takeover_denied?).and_return(true)
      expect(bue_product).not_to be_transfer_state_updated
    end

    it "returns the product message deny_takeover!" do
      expect(bue_product.product_message).to eq(:deny_takeover!)
    end

    it "calls the product message" do
      expect(product).to receive(:deny_takeover!)
      allow(event_double).to receive(:update_attributes!)
      bue_product.perform_transfer_update!
    end

    it "updates the business event" do
      allow(product).to receive(:deny_takeover!)
      parsed_date = Date.strptime(date_of_denial, "%d.%m.%Y")
      expect(event_double).to receive(:update_attributes!).with(created_at: parsed_date)
      bue_product.perform_transfer_update!
    end
  end

  context "product transferred away" do
    let(:bue_product) { described_class.new(denied_row) }
    let(:date_of_transfer_away) { random_seed.days.ago.advance(days: 1).strftime("%d.%m.%Y") }
    let(:denied_row) do
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
        date_of_transfer_away,
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

    before do
      arel_double = n_double("arel_double")
      allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
      allow(arel_double)
        .to receive(:find_by)
        .with(id: product_clark_id)
        .and_return(product)
    end

    it "has a portfolio transfer state update" do
      expect(bue_product).to be_transfer_state_updated
    end

    it "has a portfolio transfer state update too, if already under management" do
      allow(product).to receive(:takeover_requested?).and_return(false)
      allow(product).to receive(:under_management?).and_return(true)
      expect(bue_product).to be_transfer_state_updated
    end

    it "has no update too, if already in target state" do
      allow(product).to receive(:takeover_requested?).and_return(false)
      allow(product).to receive(:under_management?).and_return(false)
      allow(product).to receive(:takeover_denied?).and_return(true)
      expect(bue_product).not_to be_transfer_state_updated
    end

    it "returns the product message deny_takeover!" do
      expect(bue_product.product_message).to eq(:deny_takeover!)
    end

    it "calls the product message" do
      expect(product).to receive(:deny_takeover!)
      allow(event_double).to receive(:update_attributes!)
      bue_product.perform_transfer_update!
    end

    it "updates the business event" do
      allow(product).to receive(:deny_takeover!)
      parsed_date = Date.strptime(date_of_transfer_away, "%d.%m.%Y")
      expect(event_double).to receive(:update_attributes!).with(created_at: parsed_date)
      bue_product.perform_transfer_update!
    end
  end

  context "denied product that is later accepted" do
    let(:bue_product) { described_class.new(denied_row) }
    let(:date_of_denial) { random_seed.days.ago.advance(days: -1).strftime("%d.%m.%Y") }
    let(:denied_row) do
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
        date_of_denial,
        date_of_denial,
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

    before do
      arel_double = n_double("arel_double")
      allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
      allow(arel_double)
        .to receive(:find_by)
        .with(id: product_clark_id)
        .and_return(product)
      allow(product).to receive(:under_management?).and_return(false)
      allow(product).to receive(:takeover_requested?).and_return(false)
      allow(product).to receive(:takeover_denied?).and_return(true)
    end

    it "has a portfolio transfer state update" do
      expect(bue_product).to be_transfer_state_updated
    end

    it "if already under management, no update needed" do
      allow(product).to receive(:under_management?).and_return(true)
      expect(bue_product).not_to be_transfer_state_updated
    end

    it "returns the product message take_under_management!" do
      expect(bue_product.product_message).to eq(:take_under_management!)
    end

    it "calls the product message" do
      expect(product).to receive(:take_under_management!)
      allow(event_double).to receive(:update_attributes!)
      bue_product.perform_transfer_update!
    end

    it "updates the business event" do
      allow(product).to receive(:take_under_management!)
      parsed_date = Date.strptime(date_of_acceptance, "%d.%m.%Y")
      expect(event_double).to receive(:update_attributes!).with(created_at: parsed_date)
      bue_product.perform_transfer_update!
    end
  end

  context "acceptable product with wrong customer" do
    let(:bue_product) { described_class.new(row) }
    let(:const_class) { FondsFinanz::TransferExcelParser }

    before do
      arel_double = n_double("arel_double")
      allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
      allow(arel_double)
        .to receive(:find_by)
        .with(id: product_clark_id)
        .and_return(product)
    end

    it "should fail, if the first name differs" do
      row[const_class::KUNDE_VORNAME_COL] = "other"
      expect(bue_product.product).to be_nil
    end

    it "should fail, if the last name differs" do
      row[const_class::KUNDE_NACHNAME_COL] = "other"
      expect(bue_product.product).to be_nil
    end

    it "should pass, if the birth date differs one day" do
      row[const_class::KUNDE_GEBURTSDATUM_COL] = (mandate.birthdate - 1.day).strftime("%d.%m.%Y")
      expect(bue_product.product).not_to be_nil
    end

    it "fail, if the birth date differs more than one day" do
      row[const_class::KUNDE_GEBURTSDATUM_COL] = (mandate.birthdate - 2.day).strftime("%d.%m.%Y")
      expect(bue_product.product).to be_nil
    end
  end

  context "inexact matching" do
    let(:product_clark_id) { product.id }
    let(:bue_product) { described_class.new(row) }
    let(:mandate) do
      instance_double(
        Mandate,
        first_name: first_name,
        last_name: last_name,
        birthdate: Date.strptime(date_of_birth, "%d.%m.%Y").noon.in_time_zone
      )
    end
    let(:product) do
      instance_double(
        Product,
        id: 123,
        mandate: mandate,
        takeover_requested?: true,
        termination_pending?: false,
        terminated?: false
      )
    end

    before do
      arel_double = n_double("arel_double")
      allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
      allow(arel_double)
        .to receive(:find_by)
        .with(id: product_clark_id)
        .and_return(product)
    end

    def self.matching_names(clark_first_name, clark_last_name, ff_first_name, ff_last_name, &spec)
      context "clark's #{clark_first_name.inspect} #{clark_last_name.inspect} " \
        "and ff's #{ff_first_name.inspect} #{ff_last_name.inspect}" do
        subject { bue_product.product }

        let(:first_name) { clark_first_name }
        let(:last_name) { clark_last_name }

        before do
          row[FondsFinanz::TransferExcelParser::KUNDE_VORNAME_COL] = ff_first_name
          row[FondsFinanz::TransferExcelParser::KUNDE_NACHNAME_COL] = ff_last_name
        end

        it &spec
      end
    end

    context "when customer name has a middle name" do
      context "in the first name" do
        matching_names("Thommy", "Kathert", "Thommy Boris", "Kathert") { is_expected.not_to be_nil }
        matching_names("Max Iturbe", "Bernabe Faber", "Max", "Bernabe Faber") { is_expected.not_to be_nil }
      end

      context "in the last name" do
        matching_names("Max", "Faber", "Max", "Bernabe Faber") { is_expected.not_to be_nil }
        matching_names("Max Iturbe", "Bernabe Faber", "Max Iturbe", "Faber") { is_expected.not_to be_nil }
      end
    end

    context "when case is inconsistent" do
      matching_names("Thomas", "Müller", "thomas", "müller") { is_expected.not_to be_nil }
      matching_names("Thomas", "Müller", "THOMAS", "MÜLLER") { is_expected.not_to be_nil }
    end

    context "when there's extra whitespace" do
      matching_names("Thomas", "Müller", " Thomas", "Müller ") { is_expected.not_to be_nil }
      matching_names(" Thomas", " Müller ", "Thomas", "Müller") { is_expected.not_to be_nil }
    end

    context "when there're diacritics" do
      matching_names("Thomas", "Heß", "Thomas", "Hess") { is_expected.not_to be_nil }
      matching_names("Thomas", "Müller", "Thomas", "Mueller") { is_expected.not_to be_nil }
      matching_names("René", "Kathert", "Rene", "Kathert") { is_expected.not_to be_nil }
    end

    context "with partial complex last names" do
      matching_names("Thomas", "Müller", "Thomas", "Müller-Schneider") { is_expected.not_to be_nil }
      matching_names("Thomas", "Müller-Schneider", "Thomas", "Müller") { is_expected.not_to be_nil }

      matching_names("Thomas", "Müller-Something", "Thomas", "Müller-Schneider") { is_expected.to be_nil }
    end

    context "with title included in name" do
      matching_names("Dr. Thomas", "Müller", "Thomas", "Müller") { is_expected.not_to be_nil }
      matching_names("Thomas", "Müller", "Dr Thomas", "Müller") { is_expected.not_to be_nil }
    end

    context "with first name only is a shortcut" do
      matching_names("T.", "Müller", "Thomas", "Müller") {is_expected.not_to be_nil}
      matching_names("Thomas", "Müller", "T.", "Müller") {is_expected.not_to be_nil}
    end

    context "with first name in ff is undefined (temporarily)" do
      matching_names("Thomas", "Müller", nil, "Müller") { is_expected.to be_nil }
    end
  end
end
