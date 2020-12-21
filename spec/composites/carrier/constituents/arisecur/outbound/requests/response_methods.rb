# frozen_string_literal: true

RSpec.shared_examples "response_methods" do
  describe "#response_successful?" do
    context "when response is success and body is processable" do
      let(:response) { double(:response, success?: true, body: "{\"Id\":\"1\"}") }

      it { expect(request.response_successful?).to eq true }
    end

    context "when response is failed" do
      let(:response) { double(:response, success?: false, body: "{\"Id\":\"1\"}") }

      it { expect(request.response_successful?).to eq false }
    end

    context "when response body is not processable" do
      let(:response) { double(:response, success?: true, body: "test") }

      it { expect(request.response_successful?).to eq false }
    end
  end

  describe "#response_body" do
    context "when response body is not processable" do
      let(:response) { double(:response, success?: true, body: "test") }

      it { expect(request.response_body).to eq({}) }
    end

    context "when response body is processable" do
      let(:response) { double(:response, success?: true, body: "{\"Id\":\"1\"}") }

      it { expect(request.response_body).to eq({ "Id" => "1" }) }
    end
  end
end
