# frozen_string_literal: true

require "rails_helper"

describe FondsFinanz::TransferCsvBuilder, :integration do
  context "encoding conversions" do
    let(:supported_characters) do
      %w[
        ć
        Ć
      ]
    end
    let(:now) { Date.new(2019, 3, 17).noon }
    let(:premium_period_mapping) { ["month", 12] }
    let(:contract_started_at) { now - 6.months }
    let(:contract_ended_at) { now + 6.months }

    def subject_with_product_from_user_with_full_name(first, last)
      mandate = create(:mandate, first_name: first, last_name: last, gender: :female)
      create(
        :product,
        mandate: mandate,
        contract_started_at: contract_started_at,
        contract_ended_at: contract_ended_at,
        premium_period: premium_period_mapping[0]
      )
    end

    before do
      Timecop.freeze(now)
    end

    after do
      Timecop.return
    end

    it "does not break if full_name has special characters" do
      products = supported_characters.map do |character|
        first_name = "fabu#{character}"
        last_name = "babu#{character}"
        subject_with_product_from_user_with_full_name(first_name, last_name)
      end
      csv = nil
      expect {
        csv = FondsFinanz::TransferCsvBuilder.new(Product.where(id: products.map(&:id))).generate
      }.not_to raise_exception

      lines = csv.split("\n")
      header_line = lines[0]
      expect(header_line).to eq(described_class::HEADERS.join(described_class::SEPARATOR))
      first_data_line = lines[1]
      product = products[0]

      date_format = "%d.%m.%Y"
      mandate = product.mandate
      expected_birthdate = mandate.birthdate.strftime(date_format)
      vertical_ident = product.category.vertical.ident
      price = product.premium_price.to_i
      gross_net = I18n.t("attribute_domains.premium_type.#{product.category.premium_type}")
      contract_start = contract_started_at.strftime(date_format)
      contract_end = contract_ended_at.strftime(date_format)
      ff_subcompany_ident = product.plan.subcompany.ff_ident
      mandate_file_name = "mv#{mandate.first_name}#{mandate.last_name}#{product.id}".parameterize + ".pdf"
      data_protection_filename = "ds#{product.id}.pdf"

      expected_data = [
        "Frau",
        "Fabuc",
        "Babuc",
        expected_birthdate,
        product.number,
        vertical_ident,
        price,
        gross_net,
        premium_period_mapping[1],
        contract_start,
        contract_end,
        ff_subcompany_ident,
        mandate_file_name,
        data_protection_filename,
        product.id
      ]

      expect(first_data_line).to eq(expected_data.join(";"))
    end
  end
end
