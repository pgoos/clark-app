# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfLoadingService do

  let(:valid_test_uri) { URI("https://test.local/fake.pdf") }
  let(:insecure_test_uri) { URI("http://test.local/fake.pdf") }

  context "remote service http error handling" do
    let(:fake_response) { double(message: "fake message", response_body_permitted?: true, body: "binary_pdf_string", code: "200") }
    let(:remote_service) { PdfLoadingService::RemoteService }

    before do
      allow(Net::HTTP).to receive(:start) { fake_response }
    end

    it "should succeed, if the request returned a status code 200" do
      expect(remote_service.download_securely(valid_test_uri, {})).to eq(fake_response.body)
    end

    it "should raise, if the request did not succeed for client reasons" do
      allow(fake_response).to receive(:code) { "400" }
      expect {
        remote_service.download_securely(valid_test_uri, {})
      }.to raise_error("Http request failed! Host: '#{valid_test_uri.host}', Response code: '#{fake_response.code}', response message: '#{fake_response.message}', response body: '#{fake_response.body}'")
    end

    it "should raise, if the request did not succeed for server reasons" do
      allow(fake_response).to receive(:code) { "500" }
      expect {
        remote_service.download_securely(valid_test_uri, {})
      }.to raise_error("Http request failed! Host: '#{valid_test_uri.host}', Response code: '#{fake_response.code}', response message: '#{fake_response.message}', response body: '#{fake_response.body}'")
    end

    it "should succeed, if the request returned a status code 304" do
      allow(fake_response).to receive(:code) { "304" }
      expect {
        remote_service.download_securely(valid_test_uri, {})
      }.not_to raise_error
    end

    it "should raise, if a basic authentication is missing a password" do
      expect {
        remote_service.download_securely(valid_test_uri, {basic_user: "user1"})
      }.to raise_error("Basic authentication data is incomplete! We're missing: :basic_pw")
    end

    it "should raise, if a basic authentication is missing a user" do
      expect {
        remote_service.download_securely(valid_test_uri, {basic_pw: "pw1"})
      }.to raise_error("Basic authentication data is incomplete! We're missing: :basic_user")
    end

    it "should raise, if the request did not succeed for server reasons" do
      expect(remote_service.download_securely(valid_test_uri, {basic_user: "user1", basic_pw: "pw1"})).to eq(fake_response.body)
    end
  end

  context "correct and erroneous arguments" do
    it "should load a pdf" do
      pdf = PdfLoadingService.download_securely(valid_test_uri)
      expect(pdf).to_not be_blank
    end

    it "should validate the url schme to be https" do
      expect {
        PdfLoadingService.download_securely(insecure_test_uri)
      }.to raise_error(ArgumentError, "The URL scheme is required to be https!")
    end

    it "should check the presence of an URI" do
      expect {
        PdfLoadingService.download_securely(nil)
      }.to raise_error(ArgumentError, "Provide a URI!")
    end

    it "should check the presence of an options hash" do
      expect {
        PdfLoadingService.download_securely(valid_test_uri, nil)
      }.to raise_error(ArgumentError, "Provide an options hash!")
    end
  end
end
