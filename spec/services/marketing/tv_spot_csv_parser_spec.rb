# frozen_string_literal: true

require 'rails_helper'

describe Marketing::TvSpotCsvParser do
  let(:parser) { Marketing::TvSpotCsvParser.new }

  context 'vendor tv_generic' do
    it 'should extract the tv channel' do
      spots = []
      parser.parse(StringIO.new(csv_welt_n24_with_one_line)) do |tv_spot|
        spots << tv_spot
      end
      expect(spots[0][:tv_channel]).to eq("WELT")
    end

    it 'should extract the air time' do
      spots = []
      parser.parse(StringIO.new(csv_welt_n24_with_one_line)) do |tv_spot|
        spots << tv_spot
      end
      date_string = "5/1/16"
      date = Date.strptime(date_string, "%m/%d/%y")
      offset = UtcOffsetCalculator.utc_day_end_offset_for_date(date)
      expected_datetime = Time.zone.strptime("2016-05-01 06:46:00.000000000 +#{offset}", "%Y-%m-%d %H:%M:%S.%N %z").utc
      expect(spots[0][:air_time]).to eq(expected_datetime)
    end

    it 'should extract the price' do
      spots = []
      parser.parse(StringIO.new(csv_welt_n24_with_one_line)) do |tv_spot|
        spots << tv_spot
      end
      expect(spots[0][:price_cents]).to eq(13500)
      expect(spots[0][:price_currency]).to eq('EUR')
    end

    it 'should extract the price, if no comma is given' do
      spots = []
      parser.parse(StringIO.new(csv_welt_n24_with_one_line_no_comma_price)) do |tv_spot|
        spots << tv_spot
      end
      expect(spots[0][:price_cents]).to eq(13500)
      expect(spots[0][:price_currency]).to eq('EUR')
    end

    it 'should write all fields into the vendor specific data field' do
      spots = []
      parser.parse(StringIO.new(csv_welt_n24_with_one_line)) do |tv_spot|
        spots << tv_spot
      end
      expect(spots[0][:vendor_specific_data]).not_to be_empty
    end
  end

  describe "#parse_and_create_range_tv_spots" do
    let(:starting_at) { Date.strptime("2016-5-1", "%Y-%m-%d") }
    let(:ending_at) { Date.strptime("2016-5-2", "%Y-%m-%d") }
    let(:csv_file) {
      file_fixture("tv_spots/sample_tv_spots.csv")
    }
    let(:brand) { false }

    it "creates tv spots entries that fall in the range between start and end date" do
      expect {
        parser.parse_and_create_range_tv_spots(csv_file, starting_at, ending_at, brand)
      }.to change(TvSpot, :count).by(2)
    end
  end

  describe ".default_tv_discount" do
    it "returns Dummy Discount as a default" do
      default_tv_discount = create(:tv_discount, name: described_class.default_tv_discount_name)
      expect(described_class.default_tv_discount).to eq(default_tv_discount)
    end

    it "returns the last tv discount available if the dummy discount is not available" do
      random_tv_discount = create(:tv_discount)
      expect(described_class.default_tv_discount).to eq(random_tv_discount)
    end
  end

  describe ".destroy_old_entries" do
    let(:starting_at) { Time.new(2016, 5, 1).in_time_zone }
    let(:ending_at) { Time.new(2016, 5, 2).in_time_zone }
    let(:brand) { false }

    it "delete old entries with an airing date within the range defined" do
      create(:tv_spot, air_time: Time.new(2016, 5, 1).in_time_zone)
      expect { described_class.destroy_old_entries(starting_at, ending_at, brand) }.to change(TvSpot, :count).by(-1)
    end

    it "will not delete old entries with an airing date out of the range defined" do
      create(:tv_spot, air_time: Time.new(2016, 6, 1).in_time_zone)
      expect { described_class.destroy_old_entries(starting_at, ending_at, brand) }.not_to change(TvSpot, :count)
    end

    it "will not delete entries with a different brand dimension" do
      create(:tv_spot, air_time: Time.new(2016, 5, 1).in_time_zone, brand: false)
      expect {
        described_class
          .destroy_old_entries(starting_at, ending_at, brand: true)
      }.not_to change(TvSpot, :count)
    end
  end

  def csv_welt_n24_with_one_line
    <<~EOT
      # vendor: tv_generic
      Sender,Tag,GfK-Tag,Planzeit,Preis,Umfeld,Produkt,Motiv,Dauer in Sek.,Reichweite in Tausend,spot-id
      WELT,So,5/1/16,6:46:00 AM,"135,00",Nachtwölfe - Russlands härteste Motorrad-Gang,News,20 Sec.,20,10,10131293
    EOT
  end

  def csv_welt_n24_with_one_line_no_comma_price
    <<~EOT
      # vendor: tv_generic
      Sender,Tag,GfK-Tag,Planzeit,Preis,Umfeld,Produkt,Motiv,Dauer in Sek.,Reichweite in Tausend,spot-id
      WELT,So,5/1/16,6:46:00 AM,135.00,Nachtwölfe - Russlands härteste Motorrad-Gang,News,20 Sec.,20,10,10131293
    EOT
  end
end
