# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypeformService::TypeformApiProxy do
  describe "#get_from_typeform_api" do
    subject { TypeformService::TypeformApiProxy.get_from_typeform_api("12345") }

    before { allow_any_instance_of(Net::HTTP).to receive(:get).and_return(netresponse) }

    context "when response code is 200" do
      let(:netresponse) { double("response", body: "{\"this is a test\": \"test\"}", code: "200") }

      it "returns parsed body" do
        expect(subject).to eq("this is a test" => "test")
      end
    end

    context "when response code is 404" do
      let(:netresponse) { double("response", body: "{\"this is a test\": \"test\"}", code: "404") }

      it "returns TypeformService::NotFound error" do
        expect { subject }.to raise_error(TypeformService::NotFound)
      end
    end

    context "when response code is 403" do
      let(:netresponse) { double("response", body: "{\"this is a test\": \"test\"}", code: "403") }

      it "returns TypeformService::AuthenticationFailed" do
        expect { subject }.to raise_error(TypeformService::AuthenticationFailed)
      end
    end

    context "when response code is not 200" do
      let(:netresponse) { double("response", body: "{\"this is a test\": \"test\"}", code: "500") }

      it "returns StandardError" do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
