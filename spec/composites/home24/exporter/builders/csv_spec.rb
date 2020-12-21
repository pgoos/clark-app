# frozen_string_literal: true

require "rails_helper"
require "composites/home24/exporter/builders/csv"

RSpec.describe Home24::Exporter::Builders::Csv do
  subject { described_class.new("#{customer_data['order_id']}.csv") }

  let(:customer_data) {
    {
      "broker_number" => "512345678",
      "insurance_category" => "NEO-Gegenstandspolice",
      "order_id" => Faker::Number.number(digits: 10),
      "salutation" => Faker::Gender.binary_type,
      "title" => nil,
      "first_name" => Faker::Name.first_name,
      "last_name" => Faker::Name.last_name,
      "name_2" => nil,
      "citizenship" => nil,
      "birthdate" => Faker::Time.between(from: 80.years.ago, to: 18.years.ago).iso8601,
      "street" => Faker::Address.street_name,
      "house_number" => Faker::Address.building_number,
      "zipcode" => Faker::Address.zip_code,
      "city" => Faker::Address.city,
      "private_phone_number" => Faker::PhoneNumber.cell_phone,
      "mobile_phone_number" => nil,
      "email" => Faker::Internet.email,
      "contract_started_at" => Faker::Time.between(from: 5.days.ago, to: 1.day.ago).iso8601,
      "contract_ended_at" =>  Faker::Time.between(from: DateTime.now + 1.month, to: DateTime.now + 2.years).iso8601,
      "gross_annual_premium" => "#{Faker::Number.between(from: 1, to: 100)} Euro",
      "brokerage_rate" => nil,
      "tariff" => "Clark_Mini_HR",
      "deductible_amount" => 0,
      "sum_insured" => Faker::Number.number(digits: 4)
    }
  }

  describe "#generate" do
    it "generates file with correct file name" do
      file = subject.generate(customer_data)

      expect(file.name).to eq("#{customer_data['order_id']}.csv")
    end

    it "returns an entity of Home24::Exporter::Builders::Csv:FIle" do
      file = subject.generate(customer_data)

      expect(file).to be_kind_of(Home24::Exporter::Builders::Csv::File)
    end

    it "builds header row correct with all required columns" do
      header_row = subject.generate(customer_data).content.split("\n")[0]

      expect(header_row).to eq(described_class::FIELDS_MAPPING.keys.join(described_class::SEPARATOR))
    end

    it "builds csv with two lines" do
      content = subject.generate(customer_data).content

      expect(content.lines.count).to eq(2)
    end

    it "builds correctly customer data row" do
      customer_row_details = subject.generate(customer_data).content.split("\n").last
      expect(customer_row_details).to eq(customer_data.values.join(described_class::SEPARATOR))
    end
  end
end
