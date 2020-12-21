# frozen_string_literal: true

require "write_xlsx"

module Helpers
  module XlsxFondFinanzPayments
    module_function

    HEADERS = [
      "Vertragsnummer extern", "Kunde", "Abrechnungsnummer", "Abrechnungsdatum", "Summe in EUR", "Provisionsart"
    ].freeze

    def generate(product_number, customer)
      name = "FondFinanz#{Time.now.to_i}"
      path = Helpers::OSHelper.upload_file_path("#{name}.xlsx")
      workbook = WriteXLSX.new(path)
      worksheet = workbook.add_worksheet
      [HEADERS, row(product_number, customer)].each_with_index do |row, row_index|
        row.each_with_index { |data, col_index| worksheet.write(row_index, col_index, data) }
      end
      workbook.close
      File.new(path)
    end

    def row(product_number, customer)
      [
        product_number,
        "(VN)#{customer.last_name}, #{customer.first_name}",
        Faker::Base.numerify("##########"),
        Faker::Date.between(from: 2.days.ago, to: 1.day.ago).strftime("%d.%m.%Y"),
        Faker::Number.number(digits: 3),
        "Abschlussprovision"
      ]
    end
  end
end
