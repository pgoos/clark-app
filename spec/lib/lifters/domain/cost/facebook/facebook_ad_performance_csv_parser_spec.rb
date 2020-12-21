# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::Facebook::CsvParser do
  Time.use_zone("Europe/Berlin") do
    let(:parser) do
      parser = Domain::Cost::AdvertiserCostParser.new
      vendor = Domain::Cost::Facebook::CsvParser::AD_PROVIDER_NAME
      asset  = csv_io
      parser.init_parser(vendor, asset)
      parser
    end
    let(:csv_io) { csv_io(csv) }
    let(:file_mode) { "r" }
    let(:utc_offset) { 1 }

    def get_attributes(cost_update)
      cost_update.instance_variable_get(:@attributes)
    end

    it "should extract the add name" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expect(ads[0][:creative_name]).to eq("1%LA- FB-DE-Android-MF-28+-Feb16-Ad01")
    end

    it "should extract the cost" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expect(ads[0][:cost_cents]).to eq(55)
      expect(ads[0][:cost_currency]).to eq("EUR")
    end

    it "should extract the proper cost for values without fractions of euros" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expect(ads[1][:cost_cents]).to eq(100)
      expect(ads[1][:cost_currency]).to eq("EUR")
    end

    it "should extract the end_report_interval" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expected_datetime = DateTime.strptime("2016-02-11 23:59:59.999999999 +#{utc_offset}", "%Y-%m-%d %H:%M:%S.%N %z").utc
      expect(ads[0][:end_report_interval]).to eq(expected_datetime)
    end

    it "should extract the start_report_interval" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expected_datetime = DateTime.strptime("2016-02-11 00:00:00.000000000 +#{utc_offset}", "%Y-%m-%d %H:%M:%S.%N %z").utc
      expect(ads[0][:start_report_interval]).to eq(expected_datetime)
    end

    it "should extract the campaign name" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expect(ads[0][:campaign_name]).to eq("1%-LA-ANDR-AI-Phone-Feb16")
    end

    it "should extract the ad group name" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expect(ads[0][:adgroup_name]).to eq("1%LA- FB-DE-Andr-MF-28+-Feb 2016")
    end

    it "should add the ad_provider" do
      ads = []
      parser.each_cost do |cost_update|
        ads << get_attributes(cost_update)
      end
      expect(ads[0][:ad_provider]).to eq("Facebook Installs")
    end

    context "parser factory" do
      let(:parser_factory) { Domain::Cost::AdvertiserCostParser.new }
      let(:vendors) { parser_factory.allowed_vendors }

      it "should be connected to the factory" do
        expect(vendors).to include(Domain::Cost::Facebook::CsvParser.vendor)
      end
    end

    def csv
      <<EOT
# vendor: Facebook Installs
"Ad Name",Delivery,Results,"Result Type",Reach,"Cost per Result (EUR)","Amount Spent (EUR)","Relevance Score","Ad ID","Reporting Ends","Account ID","Reporting Starts","Campaign ID",Campaign,"Ad Set",Account,"Ad Set ID"
"1%LA- FB-DE-Android-MF-28+-Feb16-Ad01",active,0,actions:mobile_app_install,434,0,0.55,,6036284292267,2016-02-11,433428786840572,2016-02-11,6036284236667,1%-LA-ANDR-AI-Phone-Feb16,"1%LA- FB-DE-Andr-MF-28+-Feb 2016",Clark.de,6036284291667
IOS_retarg_web_visit_AI_Feb16_MF28+_Ad01-w2,active,0,actions:mobile_app_install,3,0,1,,6036200096467,2016-02-11,433428786840572,2016-02-11,6035797163067,IOS_RET_web_visit_AI_phone_Feb16,IOS_retarg_web_visit_AI_Feb16_MF28+,Clark.de,6035797199267
IOS_retarg_web_visit_AI_Feb16_MF28+_Ad01,active,0,actions:mobile_app_install,4,0,0,,6035797431667,2016-02-11,433428786840572,2016-02-11,6035797163067,IOS_RET_web_visit_AI_phone_Feb16,IOS_retarg_web_visit_AI_Feb16_MF28+,Clark.de,6035797199267
Andr_retarg_web_visit_AI_MF_28+_Feb16_Ad01,active,0,actions:mobile_app_install,1,0,0,,6036288521467,2016-02-11,433428786840572,2016-02-11,6036288520467,ANDR_RET_web_visit_AI_phone_Feb16,Andr_retarg_web_visit_AI_MF_28+_Feb16,Clark.de,6036288520867
EOT
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

    allow(File).to receive(:open).with(sample_path, file_mode).and_return(io)

    io
  end

  context Domain::Cost::Facebook::CsvIO do
    let(:csv_io) { StringIO.new(dirty_csv) }
    let(:target) { [] }
    let(:facebook_io) { Domain::Cost::Facebook::CsvIO.new(csv_io) }

    it "should receive the headers" do
      facebook_io.each do |line|
        target << line
      end
      expect(target).to include("\"Reporting Starts\",\"Reporting Ends\",\"Ad Name\",\"Ad Set Name\",\"Campaign Name\",Impressions,Frequency,Reach,\"Relevance Score\",\"Unique Clicks (All)\",\"Clicks (All)\",\"Mobile App Starts [1 Day After Viewing]\",\"Mobile App Starts [28 Days After Clicking]\",\"Mobile App Installs [1 Day After Viewing]\",\"Mobile App Installs [28 Days After Clicking]\",\"Mobile App Purchases [1 Day After Viewing]\",\"Mobile App Purchases [28 Days After Clicking]\",\"Amount Spent (EUR)\"\n")
    end

    it "should ignore all lines before the headers" do
      facebook_io.each do |line|
        target << line
      end
      expect(target).to_not include("\"Preliminary stuff of which we don't know, if it will ever exist\"\n")
    end

    it "should receive value lines" do
      facebook_io.each do |line|
        target << line
      end
      expect(target[1]).to eq("2016-03-11,2016-03-11,I:C7_TYP:PROD_ID:P1_F:AS_SF:PCOM_DET:MEN_AT:NF_CTA:DL_CPY:GEN-A_EMT:FREE_LP:PS,I:T5_CY:DE_F:LAL_SF:APP_CH:API_DET:AND-1%_CSS:M_DEV:AND_PL:mobilefeed,CY:DE_L:MAR_CH:FB_TY:MIX_OB:AND-APP-INSTALLS,2321,1.0095693779904,2299,1,13,17,,1,,1,,1,41.42\n")
    end

    it "should drop totals" do
      facebook_io.each do |line|
        target << line
      end
      expect(target).to_not include("2016-02-13,2016-03-13,,,,537587,1.8441270200643,291513,,2312,2726,698,919,58,376,19,56,5234.65\n")
    end

    it "should drop comments" do
      facebook_io.each do |line|
        target << line
      end
      expect(target).to_not include("# comment\n")
    end

    def dirty_csv
      <<EOT
"Preliminary stuff of which we don't know, if it will ever exist"
"Reporting Starts","Reporting Ends","Ad Name","Ad Set Name","Campaign Name",Impressions,Frequency,Reach,"Relevance Score","Unique Clicks (All)","Clicks (All)","Mobile App Starts [1 Day After Viewing]","Mobile App Starts [28 Days After Clicking]","Mobile App Installs [1 Day After Viewing]","Mobile App Installs [28 Days After Clicking]","Mobile App Purchases [1 Day After Viewing]","Mobile App Purchases [28 Days After Clicking]","Amount Spent (EUR)"
2016-02-13,2016-03-13,,,,537587,1.8441270200643,291513,,2312,2726,698,919,58,376,19,56,5234.65
2016-03-11,2016-03-11,I:C7_TYP:PROD_ID:P1_F:AS_SF:PCOM_DET:MEN_AT:NF_CTA:DL_CPY:GEN-A_EMT:FREE_LP:PS,I:T5_CY:DE_F:LAL_SF:APP_CH:API_DET:AND-1%_CSS:M_DEV:AND_PL:mobilefeed,CY:DE_L:MAR_CH:FB_TY:MIX_OB:AND-APP-INSTALLS,2321,1.0095693779904,2299,1,13,17,,1,,1,,1,41.42
# comment
EOT
    end
  end
end
