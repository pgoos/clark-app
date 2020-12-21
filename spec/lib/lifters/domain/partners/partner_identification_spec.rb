require "rails_helper"

RSpec.describe Domain::Partners::PartnerIdentification do
  it "should identifiy finanzblick" do
    expect(described_class.identify("finanzblick")).to eq("finanzblick")
  end
  it "should identifiy assona" do
    expect(described_class.identify("assona")).to eq("assona")
  end

  it "should not identifiy if empty" do
    expect(described_class.identify("")).to be_nil
  end

  it "should not identifiy if wrong" do
    expect(described_class.identify("wrong")).to be_nil
  end

  it "should identify the wrong source" do
    expect(described_class.identify_source("wrong")).to be_falsey
  end

  it "should identify the correct source" do
    expect(described_class.identify_source("assona")).to be_truthy
  end

  it "should identify the empty source" do
    expect(described_class.identify_source("")).to be_falsey
  end

  it "should return the query param 'finanzblick' specified" do
    param = described_class.get_uri_param("http://anything.de/de/signup?referrer=finanzblick&ref=007", "referrer")
    expect(param).to eq("finanzblick")
  end

  it "should return the query param 'assona' specified" do
    param = described_class.get_uri_param("http://anything.de/de/signup?referrer=assona&ref=007", "referrer")
    expect(param).to eq("assona")
  end

  it "should return a different referrer query param specified" do
    param = described_class.get_uri_param("http://anything.de/de/signup?referrer=other&ref=007", "referrer")
    expect(param).to eq("other")
  end

  it "should return a different referrer when different query param specified" do
    param = described_class.get_uri_param("http://anything.de/de/signup?referrer=other&ref=007", "ref")
    expect(param).to eq("007")
  end

  it "should return nil if referrer query param specified is present" do
    param = described_class.get_uri_param("http://anything.de/de/signup?referrer=other&ref=007", "refresh")
    expect(param).to be_nil
  end

  it "should return nil if empty param is passed" do
    param = described_class.get_uri_param("http://anything.de/de/signup", "dfdfd")
    expect(param).to be_nil
  end

  it "should return partner_customer_id if pc_id param is passed" do
    param = described_class.get_uri_param("http://anything.de/de/signup?pc_id=123&utm_source=43234", "pc_id")
    expect(param).to eq("123")
  end

  it "should return nil if pc_id param is not present" do
    param = described_class.get_uri_param("http://anything.de/de/signup?utm_source=43234", "pc_id")
    expect(param).to be_nil
  end
end
