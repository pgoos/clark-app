# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::CsvVendorParser do
  let(:parser) { Marketing::TvSpotCsvParser.new(false) } # use the tv spot parser as an example
  let(:vendor_error_message) { "Vendor token missing!" }

  context 'vendor' do
    it 'should fail, if the heading comment is missing' do
      input_io = StringIO.new('')
      expect {
        parser.parse(input_io)
      }.to raise_error(vendor_error_message)
    end

    it 'should fail, if it contains only white space' do
      input_io = StringIO.new("\n\t\r ")
      expect {
        parser.parse(input_io)
      }.to raise_error(vendor_error_message)
    end

    it 'should fail, if the input is nil' do
      expect {
        parser.parse(nil)
      }.to raise_error(vendor_error_message)
    end

    it 'should return the vendor, if the vendor header has been seen' do
      csv_with_vendor_comment = StringIO.new("# vendor: pro7_sat1\n")
      expect(parser.parse(csv_with_vendor_comment)).to eq('pro7_sat1')
    end

    it 'should return the right vendor, if a different one is given' do
      csv_with_vendor_comment = StringIO.new("# vendor: other_tv_channel\n")
      expect(parser.parse(csv_with_vendor_comment)).to eq('other_tv_channel')
    end

    it 'should ignore surrounding white space by extracting the vendor' do
      csv_with_vendor_comment = StringIO.new("# vendor: \t other_tv_channel \t \n")
      expect(parser.parse(csv_with_vendor_comment)).to eq('other_tv_channel')
    end

    it 'should allow white space within the vendor name' do
      csv_with_vendor_comment = StringIO.new("# vendor: \t other tv channel \t \n")
      expect(parser.parse(csv_with_vendor_comment)).to eq('other tv channel')
    end

    it "should allow parentheses in a vendor string" do
      expected_vendor = "Google Adwords GDN/UAC (From March 23, 2017)"
      csv_with_vendor_comment = StringIO.new("# vendor: #{expected_vendor}\n")
      expect(parser.parse(csv_with_vendor_comment)).to eq(expected_vendor)
    end

    it 'should only allow specific vendors' do
      spots = []
      other_vendor_csv = csv_with_one_line.gsub("tv_generic", "other_vendor")
      parser.parse(StringIO.new(other_vendor_csv)) do |tv_spot|
        spots << tv_spot
      end
      expect(spots.size).to be(0)
    end

    it "should allow to set the vendor externally" do
      parser.vendor = "tv_generic"
      spots = []
      parser.parse(StringIO.new(csv_without_vendor)) do |tv_spot|
        spots << tv_spot
      end
      expect(spots.size).to be(1)
    end
  end

  def csv_with_one_line
    <<~EOT
      # vendor: tv_generic
      Sender,Tag,GfK-Tag,Planzeit,Preis,Umfeld,Produkt,Motiv,Dauer in Sek.,Reichweite in Tausend,spot-id
      WELT,So,5/1/16,6:46:00 AM,135.00,Nachtwölfe - Russlands härteste Motorrad-Gang,News,20 Sec.,20,10,10131293
    EOT
  end

  def csv_without_vendor
    <<~EOT
      Sender,Tag,GfK-Tag,Planzeit,Preis,Umfeld,Produkt,Motiv,Dauer in Sek.,Reichweite in Tausend,spot-id
      WELT,So,5/1/16,6:46:00 AM,135.00,Nachtwölfe - Russlands härteste Motorrad-Gang,News,20 Sec.,20,10,10131293
    EOT
  end
end
