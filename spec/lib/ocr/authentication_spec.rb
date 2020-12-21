# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::Authentication, :vcr do
  context "with valid params" do
    it "should return the token and validity" do
      expect(subject.call.parse["token"]).to eq "foobartoken"
    end
  end

  context "with invalid params" do
    subject { described_class.new(username, password).call }

    let(:username) { "test.user.invalid@clark.de" }
    let(:password) { "12345678" }

    it "should raise unauthorized error" do
      expect(subject.status).to eq 403
    end

    context "with unknown response" do
      let(:http_double) { instance_double(Http::Response) }

      before do
        allow(Http).to receive(:post).and_return(http_double)
        allow(http_double).to receive(:status).and_return(404)
      end

      it "should raise obtain token error" do
        expect(subject.status).to eq 404
      end
    end
  end
end
