# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::ApiPartners::EventDispatcher do
  let(:subject) { described_class.new(Logger.new(nil)) }
  let(:example_url) { "https://www.exampleIsthisyou.de" }

  before do
    allow_any_instance_of(Logger).to receive(:error).and_return(nil)
    allow_any_instance_of(Logger).to receive(:info).and_return(nil)
  end

  context "#access_token" do
    before do
      http = double
      allow(Net::HTTP).to receive(:start).and_yield http
      allow(http).to receive(:request).with(an_instance_of(Net::HTTP::Post)).and_return(Net::HTTPResponse)
    end

    context "when the response is valid" do
      it "successfully handles the response" do
        allow(Net::HTTPResponse).to receive(:body).and_return({access_token: "token1234"}.to_json)
        allow(Net::HTTPResponse).to receive(:code).and_return(200)
        expect(subject.access_token(example_url, body: "something")).to eq("token1234")
      end
    end

    context "when the response is invalid" do
      it "successfully handles the response" do
        allow(Net::HTTPResponse).to receive(:body).and_return({message: "something went wrong"}.to_json)
        allow(Net::HTTPResponse).to receive(:code).and_return(400)
        expect { subject.access_token(example_url, body: "something") }.to raise_error(RuntimeError)
      end
    end

    context "when the access_token is not present" do
      it "successfully handles the response" do
        allow(Net::HTTPResponse).to receive(:body).and_return({access_token_not_there: "asdadsa"}.to_json)
        allow(Net::HTTPResponse).to receive(:code).and_return(200)
        expect { subject.access_token(example_url, body: "something") }.to raise_error(RuntimeError)
      end
    end
  end

  context "#dispatch_event" do
    context "when the response is valid" do
      it "does not throw an exception" do
        allow(Net::HTTPResponse).to receive(:body).and_return({access_token: "token1234"}.to_json)
        allow(Net::HTTPResponse).to receive(:code).and_return(200)
        expect { subject.dispatch_event(example_url, {body: "something"}, "token") }.not_to raise_error
      end
    end
  end
end
