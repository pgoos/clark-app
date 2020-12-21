# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Helpers::CSRFHelpers, :integration do
  class CSRFHelpersDummy
    include ClarkAPI::Helpers::CSRFHelpers

    def env
      {"rack.session" => {}}
    end
  end

  let(:helper) { CSRFHelpersDummy.new }

  describe "#masked_authenticity_token" do
    it "generates masked token" do
      allow(helper).to receive(:env).and_return("rack.session" => {
                                                  _csrf_token: "3sCFM36zQZAEo7T6QTu/uQSJTqm1pqJVTumcspxmDUg="
                                                })
      expect(helper.masked_authenticity_token.length).to eq 88
    end
  end

  describe "#valid_authenticity_token?" do
    it "returns false if token nil" do
      expect(helper.valid_authenticity_token?(nil)).to eq false
    end

    it "returns false if token empty" do
      expect(helper.valid_authenticity_token?("")).to eq false
    end

    it "returns false if token not a string" do
      expect(helper.valid_authenticity_token?([])).to eq false
    end

    it "returns false if string invalid" do
      expect(helper.valid_authenticity_token?("wrong string")).to eq false
    end

    it "returns true if string valid" do
      allow(helper).to receive(:env).and_return("rack.session" => {
                                                  _csrf_token: "3sCFM36zQZAEo7T6QTu/uQSJTqm1pqJVTumcspxmDUg="
                                                })
      expect(helper.valid_authenticity_token?("3sCFM36zQZAEo7T6QTu/uQSJTqm1pqJVTumcspxmDUg=")).to eq true
    end
  end

  describe "#verified_request?" do
    it "returns true if token is valid" do
      allow(helper).to receive(:env).and_return("rack.session" => {
                                                  _csrf_token: "3sCFM36zQZAEo7T6QTu/uQSJTqm1pqJVTumcspxmDUg="
                                                })
      allow(helper).to receive(:protect_against_forgery?).and_return(true)
      request = double
      allow(request).to receive(:get?).and_return(false)
      allow(request).to receive(:head?).and_return(false)
      allow(request).to receive(:headers).and_return({})
      allow(request).to receive(:params).and_return("_csrf" => "3sCFM36zQZAEo7T6QTu/uQSJTqm1pqJVTumcspxmDUg=")
      allow(helper).to receive(:request).and_return(request)
      expect(helper.verified_request?).to eq true
    end

    it "returns true if token is valid and url safe" do
      allow(helper).to receive(:env).and_return("rack.session" => {
                                                  _csrf_token: "3sCFM36zQZAEo7T6QTu/uQSJTqm1pqJVTumcspxmDUg="
                                                })
      allow(helper).to receive(:protect_against_forgery?).and_return(true)
      request = double
      allow(request).to receive(:get?).and_return(false)
      allow(request).to receive(:head?).and_return(false)
      allow(request).to receive(:headers).and_return({})
      allow(request).to receive(:params).and_return("_csrf" => "3sCFM36zQZAEo7T6QTu%2FuQSJTqm1pqJVTumcspxmDUg%3D")
      allow(helper).to receive(:request).and_return(request)
      expect(helper.verified_request?).to eq true
    end

    it "returns false if token is invalid" do
      allow(helper).to receive(:env).and_return("rack.session" => {
                                                  _csrf_token: "3sCFM36zQZAEo7T6QTu/uQSJTqm1pqJVTumcspxmDUg="
                                                })
      allow(helper).to receive(:protect_against_forgery?).and_return(true)
      request = double
      allow(request).to receive(:get?).and_return(false)
      allow(request).to receive(:head?).and_return(false)
      allow(request).to receive(:headers).and_return({})
      allow(request).to receive(:params).and_return("_csrf" => "wrong")
      allow(helper).to receive(:request).and_return(request)
      expect(helper.verified_request?).to eq false
    end

    context "when token is not present" do
      before do
        allow(helper).to receive(:env).and_return("rack.session" => {})
        allow(helper).to receive(:protect_against_forgery?).and_return(true)

        request = double
        allow(request).to receive(:get?).and_return(false)
        allow(request).to receive(:head?).and_return(false)
        allow(request).to receive(:headers).and_return({})
        allow(request).to receive(:params).and_return({})
        allow(helper).to receive(:request).and_return(request)
      end

      it "returns false" do
        expect(helper.verified_request?).to be_falsey
      end
    end
  end
end
