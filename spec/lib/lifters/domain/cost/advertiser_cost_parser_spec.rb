# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::AdvertiserCostParser do

  let(:io_path) { "/tmp/file/path/#{rand}" }
  let(:upload) { instance_double(ActionDispatch::Http::UploadedFile, eof?: false, path: io_path) }

  class SampleVendor1
    include Platform::CsvVendorParser

    def each_cost(io, &proc)
      # will be mocked
    end

    class << self
      def vendor
        "sample1_vendor"
      end

      def open_io(path)
        # will be mocked
      end
    end
  end

  class SampleVendor2
    include Platform::CsvVendorParser

    def each_cost(io, &proc)
      # will be mocked
    end

    class << self
      def vendor
        "sample2_vendor"
      end

      def open_io(path)
        # will be mocked
      end
    end
  end

  it "should know the allowed vendor if sample 1" do
    vendor_map = {SampleVendor1.vendor => SampleVendor1}.with_indifferent_access
    subject.instance_variable_set(:@vendors, vendor_map)
    expected_vendors = [SampleVendor1.vendor]
    expect(subject.allowed_vendors).to match_array(expected_vendors)
  end

  it "should know the allowed vendor if sample 2" do
    vendor_map = {SampleVendor2.vendor => SampleVendor2}.with_indifferent_access
    subject.instance_variable_set(:@vendors, vendor_map)
    expected_vendors = [SampleVendor2.vendor]
    expect(subject.allowed_vendors).to match_array(expected_vendors)
  end

  it "should know the allowed vendor if sample 1 + 2" do
    vendor_map = {
      SampleVendor1.vendor => SampleVendor1,
      SampleVendor2.vendor => SampleVendor2
    }.with_indifferent_access

    subject.instance_variable_set(:@vendors, vendor_map)
    expected_vendors = [SampleVendor1.vendor, SampleVendor2.vendor]
    expect(subject.allowed_vendors).to match_array(expected_vendors)
  end

  context "abstract factory" do
    let(:vendor_io1) { instance_double(Platform::CsvVendorParser::CsvIO) }
    let(:vendor_io2) { instance_double(Platform::CsvVendorParser::CsvIO) }
    let(:update_proc) { proc { |_| return } }

    before do
      vendor_map = {
        SampleVendor1.vendor => SampleVendor1,
        SampleVendor2.vendor => SampleVendor2
      }.with_indifferent_access

      allow(SampleVendor1).to receive(:open_io)
      allow(SampleVendor2).to receive(:open_io)

      subject.instance_variable_set(:@vendors, vendor_map)
    end

    it "should create the appropriate vendor parser for vendor key 1" do
      subject.init_parser(SampleVendor1.vendor, upload)
      expect(subject.instance_variable_get(:@parser)).to be_a(SampleVendor1)
    end

    it "should create the appropriate vendor parser for vendor key 2" do
      subject.init_parser(SampleVendor2.vendor, upload)
      expect(subject.instance_variable_get(:@parser)).to be_a(SampleVendor2)
    end

    it "raises an exception, if the vendor is unknown" do
      vendor = "unknown_vendor_#{rand}"
      expect {
        subject.init_parser(vendor, upload)
      }.to raise_error("Vendor '#{vendor}' not known!")
    end

    it "raises an exception, if the given asset is not some type of io or upload" do
      not_io = n_double("not_io")
      expect {
        subject.init_parser(SampleVendor1.vendor, not_io)
      }.to raise_error("The given asset of type '#{not_io.class.name}' is not an io like thing!")
    end

    it "raises an exception, if the given asset cannot be read" do
      allow(upload).to receive(:eof?).and_return(true)
      expect {
        subject.init_parser(SampleVendor1.vendor, upload)
      }.to raise_error("End of file already reached!")
    end

    it "should create the appropriate vendor parser for vendor key 1" do
      subject.init_parser(SampleVendor1.vendor, upload)
      expect(subject.instance_variable_get(:@parser)).to be_a(SampleVendor1)
    end

    it "should create the appropriate vendor parser for vendor key 2" do
      subject.init_parser(SampleVendor2.vendor, upload)
      expect(subject.instance_variable_get(:@parser)).to be_a(SampleVendor2)
    end

    it "should open the vendor io 1 for vendor 1" do
      expect(SampleVendor1).to receive(:open_io).with(io_path).and_return(vendor_io1)
      subject.init_parser(SampleVendor1.vendor, upload)
    end

    it "should open the vendor io 2 for vendor 2" do
      expect(SampleVendor2).to receive(:open_io).with(io_path).and_return(vendor_io2)
      subject.init_parser(SampleVendor2.vendor, upload)
    end

    context "each cost" do
      before do
        allow(SampleVendor1).to receive(:open_io).with(io_path).and_return(vendor_io1)
        subject.init_parser(SampleVendor1.vendor, upload)
      end

      it "should forward the cost call to the vendor" do
        expect_any_instance_of(SampleVendor1).to receive(:each_cost)
          .with(vendor_io1) { |&block| expect(block).to be(update_proc) }
        subject.each_cost(&update_proc)
      end
    end
  end
end
