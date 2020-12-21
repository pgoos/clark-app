# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::Adwords::CsvParser do
  Time.use_zone("Europe/Berlin") do
    let(:daily_performances) do
      daily_performances = []
      parser.each_cost do |cost_update|
        daily_performances << get_attributes(cost_update)
      end
      daily_performances
    end
    let(:first_parsed_entry) { daily_performances[0] }
    let(:second_parsed_entry) { daily_performances[1] }
    let(:third_parsed_entry) { daily_performances[2] }
    let(:fourth_parsed_entry) { daily_performances[3] }

    let(:file_mode) { "r:UTF-16LE" }
    let(:parser) { Domain::Cost::AdvertiserCostParser.new }
    let(:winter_date) { Date.new(2016, 1, 1) }
    let(:utc_winter_offset) { UtcOffsetCalculator.utc_day_end_offset_for_date(winter_date) }
    let(:sample_vendor) { Domain::Cost::Adwords::GdnUacParser.vendor }
    let(:bin_file) { instance_double(File) }

    before do
      parser.init_parser(sample_vendor, csv_io)
    end

    def get_attributes(update)
      update.instance_variable_get(:@attributes)
    end

    it "should extract the campaign name" do
      expect(first_parsed_entry[:campaign_name]).to eq("SEA-DE-App Store-Competitor--Vendors-BMM")
    end

    it "should extract the adgroup_name" do
      expect(first_parsed_entry[:adgroup_name]).to eq("Vendor online -BMM")
    end

    it "should extract the creative_name" do
      expect(first_parsed_entry[:creative_name]).to eq("+victoria +online")
    end

    it "should extract the creative_name and append _e if the keyword match type is 'Exact'" do
      expect(second_parsed_entry[:creative_name]).to eq("alte oldenburger app_e")
    end

    it "should extract the creative_name and remove the prefix '=' for kw match type 'Broad'" do
      expect(third_parsed_entry[:creative_name]).to eq("+allianz +vergleich")
    end

    it "should fails for insecure data to extract the creative_name" do
      parser.init_parser(sample_vendor, csv_io(insecure_kw_match_type_csv))
      expect{
        first_parsed_entry[:creative_name]
      }.to raise_error(match(/keyword_match_type not known/))
    end

    it "should have the start report interval time" do
      expected_datetime = DateTime.strptime("#{winter_date.to_s} 00:00:00.000000000 +#{utc_winter_offset}", "%Y-%m-%d %H:%M:%S.%N %z").utc
      expect(first_parsed_entry[:start_report_interval]).to eq(expected_datetime)
    end

    it "should have the end report interval time" do
      expected_datetime = DateTime.strptime("#{winter_date.to_s} 23:59:59.999999999 +#{utc_winter_offset}", "%Y-%m-%d %H:%M:%S.%N %z").utc
      expect(first_parsed_entry[:end_report_interval]).to eq(expected_datetime)
    end

    it "should extract the aggregated daily cost for a campaign and ad group" do
      expect(first_parsed_entry[:cost_cents]).to eq(270)
      expect(first_parsed_entry[:cost_currency]).to eq("EUR")
    end

    it "should fail, if there is more than one set of data for a day" do
      parser.init_parser(sample_vendor, csv_io(error_csv))
      error = 'CSV INPUT ERROR! Row: #<CSV::Row "Campaign":"SEA-DE-App Store-Competitor--Vendors-BMM" "Ad group":"Vendor online -BMM" "Search keyword":" +victoria +online" "Search keyword match type":"Broad" "Keyword max CPC":"€0.64" "Day":"05-May-2017" "Clicks":"1" "CTR":"25.00%" "Avg. CPC":"€2.70" "Avg. position":"1.00" "Cost":"€1.30">, Exception: Duplicate row!'
      expect {
        first_parsed_entry
      }.to raise_error(error)
    end

    it "should not fail, if there is similar data for a day with varying keyword_match_type" do
      parser.init_parser(sample_vendor, csv_io(csv_only_different_in_keyword_match_type))
      expect(daily_performances.size).to eq(2)
    end

    it "should not fail, if there is similar data for a day with varying search keywords" do
      parser.init_parser(sample_vendor, csv_io(csv_only_different_search_keyword))
      expect(daily_performances.size).to eq(2)
    end

    context "provider_data" do
      it "parses the keyword_match_type 'Broad'" do
        expect(first_parsed_entry[:provider_data][:keyword_match_type]).to eq("Broad")
      end

      it "parses the keyword_match_type 'Excact'" do
        expect(second_parsed_entry[:provider_data][:keyword_match_type]).to eq("Exact")
      end

      it "parses the max_cpc line 1" do
        expect(first_parsed_entry[:provider_data][:max_cpc]).to eq(64)
      end

      it "parses the max_cpc line 2" do
        expect(second_parsed_entry[:provider_data][:max_cpc]).to eq(262)
      end

      it "parses the clicks line 1" do
        expect(first_parsed_entry[:provider_data][:clicks]).to eq(0)
      end
      it "parses the clicks line 2" do
        expect(second_parsed_entry[:provider_data][:clicks]).to eq(2)
      end

      it "parses the avg_position line 1" do
        expect(first_parsed_entry[:provider_data][:avg_position]).to be_within(0.001).of(1.00)
      end
      it "parses the avg_position line 2" do
        expect(second_parsed_entry[:provider_data][:avg_position]).to be_within(0.001).of(2.34)
      end

      it "parses the ctr line 1" do
        expect(first_parsed_entry[:provider_data][:ctr]).to be_within(0.001).of(0.25)
      end

      it "parses the ctr line 2" do
        expect(second_parsed_entry[:provider_data][:ctr]).to be_within(0.001).of(0.50)
      end
    end

    class FakeIO
      def initialize(payload, path)
        @lines = payload.split("\n")
        @cursor = 0
        @path = path
      end

      attr_reader :path

      def each
        @lines.each do |line|
          yield line + "\n"
          @cursor += 1
        end
      end

      def eof?
        @cursor > @lines.size
      end

      def rewind
        @cursor = 0
      end
    end

    def csv_io(payload=csv)
      random_fraction = rand.to_s.tr('.', '')
      sample_path     = "./sample/path_#{random_fraction}"

      io = FakeIO.new(payload, sample_path)

      allow(File).to receive(:open).with(sample_path, "rb").and_return(bin_file)
      allow(bin_file).to receive(:getc).and_return("\xff", "\xfe")
      allow(bin_file).to receive(:close)

      allow(File).to receive(:open).with(sample_path, file_mode).and_return(io)

      io
    end

    def csv
      <<~EOT
        Campaign	Ad group	Search keyword	Search keyword match type	Keyword max CPC	Day	Clicks	CTR	Avg. CPC	Avg. position	Cost
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Broad	€0.64	01-Jan-2016	0	25.00%	€2.70	1.00	€2.70
        SEA-DE-App Store-Competitor--Vendors-Exact	Vendor app -Exact	alte oldenburger app	Exact	€2.62	08-May-2017	2	50.00%	€2.62	2.34	€2.62
        SEA-DE-Play Store-Competitor--Vendors-BMM	Vendor vergleich -BMM	 =+allianz +vergleich	Broad	€3.76	04-May-2017	2	20.00%	€2.92	1.00	€5.83
        SEA-DE-App Store-Generic-Insurance-App-Calculate-Exact	Versicherungsrechner-Exact	versicherungsrechner	Exact	€10.90	10-May-2017	1	3.70%	€10.84	3.78	€10.84
      EOT
    end

    def error_csv
      <<~EOT
        Campaign	Ad group	Search keyword	Search keyword match type	Keyword max CPC	Day	Clicks	CTR	Avg. CPC	Avg. position	Cost
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Broad	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€2.70
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Broad	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€1.30
      EOT
    end

    def csv_only_different_in_keyword_match_type
      <<~EOT
        Campaign	Ad group	Search keyword	Search keyword match type	Keyword max CPC	Day	Clicks	CTR	Avg. CPC	Avg. position	Cost
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Broad	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€2.70
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Exact	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€1.30
      EOT
    end

    def csv_only_different_search_keyword
      <<~EOT
        Campaign	Ad group	Search keyword	Search keyword match type	Keyword max CPC	Day	Clicks	CTR	Avg. CPC	Avg. position	Cost
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Broad	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€2.70
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +different +online	Broad	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€1.30
      EOT
    end

    def insecure_kw_match_type_csv
      <<~EOT
        Campaign	Ad group	Search keyword	Search keyword match type	Keyword max CPC	Day	Clicks	CTR	Avg. CPC	Avg. position	Cost
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	INSECURE	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€2.70
      EOT
    end
  end

  context Domain::Cost::Adwords::CsvIO do
    let(:csv_io_dirty) { csv_io(dirty_csv) }
    let(:target) { [] }
    let(:adwords_io) { Domain::Cost::Adwords::CsvIO.new(csv_io_dirty) }

    it "should receive the headers" do
      adwords_io.each do |line|
        target << line
      end
      expect(target).to include("Campaign	Ad group	Search keyword	Search keyword match type	Keyword max CPC	Day	Clicks	CTR	Avg. CPC	Avg. position	Cost\n")
    end

    it "should ignore all lines before the headers" do
      adwords_io.each do |line|
        target << line
      end
      expect(target).to_not include("\"Campaign_report_for_backend_import_L7D (Mar 7, 2016-Mar 13, 2016)\"\n")
    end

    it "should receive value lines" do
      adwords_io.each do |line|
        target << line
      end
      expect(target[1]).to eq("SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Broad	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€2.70\n")
    end

    it "should drop totals" do
      adwords_io.each do |line|
        target << line
      end
      expect(target).to_not include("Total - all but deleted campaigns	 --	 --	 --	 --	483910	2522	 --	0.52%	0.32	803.86\n")
    end

    it "should drop comments" do
      adwords_io.each do |line|
        target << line
      end
      expect(target).to_not include("# comment\n")
    end

    def dirty_csv
      <<~EOT

        "Campaign_report_for_backend_import_L7D (Mar 7, 2016-Mar 13, 2016)"

        Campaign	Ad group	Search keyword	Search keyword match type	Keyword max CPC	Day	Clicks	CTR	Avg. CPC	Avg. position	Cost
        SEA-DE-App Store-Competitor--Vendors-BMM	Vendor online -BMM	 +victoria +online	Broad	€0.64	05-May-2017	1	25.00%	€2.70	1.00	€2.70
        # comment
        Total - all but deleted campaigns	 --	 --	 --	 --	483910	2522	 --	0.52%	0.32	803.86
      EOT
    end
  end
end
