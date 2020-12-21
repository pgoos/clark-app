# frozen_string_literal: true

require "rails_helper"
require "lifters/domain/partners/mocks/fake_miles_more_client"

RSpec.describe Domain::Partners::Clients::MilesMoreClient do
  let(:auth_token) { Settings.mam.auth_token || "abcitseasy" }

  it "initializes correctly" do
    allow_any_instance_of(described_class).to receive(:authenticated_request_token).and_return(auth_token)
    client = described_class.new
    expect(client.instance_variable_get(:@token)).to eq(auth_token)
    expect(client.instance_variable_get(:@client_id)).to eq("msp_clark")
  end

  describe "#member_status" do
    subject { described_class.new.member_status("xyz") }

    context "Server Error" do
      let(:response) { double(code: 503, body: "{}") }

      context "reaches max tries" do
        before do
          allow_any_instance_of(described_class).to receive(:max_tries).and_return(2)
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
        end

        it "should raise an exception" do
          expect { subject }.to raise_error(Domain::Partners::Clients::MilesAndMoreError)
        end

        it "should inform sentry partners instance" do
          expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_exception)
          begin
            subject
          rescue Domain::Partners::Clients::MilesAndMoreError
            # skip the exception
          end
        end
      end

      context "rescuable" do
        let(:correct_response) { double("correct_response", code: 200, body: "{}") }

        before do
          # First returns bad response and second returns correct one
          allow_any_instance_of(Net::HTTP).to receive(:request)
            .and_return(response, correct_response)
        end

        it "should return the result" do
          expect(subject).to eq(success: true, data: {})
        end
      end

      context "response body is nil and reaches max tries" do
        let(:nil_response) { double("nil_response", code: 401, body: nil) }

        before do
          allow_any_instance_of(described_class).to receive(:authenticated_request_token).and_return("token")
          allow_any_instance_of(described_class).to receive(:max_tries).and_return(2)
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(nil_response)
        end

        it "should raise 'Mile and more' exception" do
          expect { subject }.to raise_error(Domain::Partners::Clients::MilesAndMoreError)
        end
      end

      context "response body is html and reaches max tries" do
        let(:html_response) { double("nil_response", code: 500, body: "<html></html>") }

        before do
          allow_any_instance_of(described_class).to receive(:authenticated_request_token).and_return("token")
          allow_any_instance_of(described_class).to receive(:max_tries).and_return(2)
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(html_response)
        end

        it "should raise 'Mile and more' exception" do
          expect { subject }.to raise_error(Domain::Partners::Clients::MilesAndMoreError)
        end
      end
    end
  end

  it "creates a correct error_text" do
    expected_error_text = /Miles and more error: .*/
    status = 400
    data = {
      "error"   => "Error",
      "status"  => "Status",
      "message" => "Message"
    }
    booking = OpenStruct.new(
      transaction_text:        "transaction_text",
      mam_property_code:       "mam_property_code",
      member_alias:            "member_alias",
      miles_to_book:           "miles_to_book",
      action:                  "action",
      additional_partner_data: "additional_partner_data"
    )
    expect(described_class.error_text(status, data, booking)).to match(expected_error_text)
  end

  it "creates a correct error_text for empty data" do
    expected_error_text = /Miles and more error: .*/
    expect(described_class.error_text(nil, nil, nil)).to match(expected_error_text)
  end

  it "refreshes its token"

  describe "#authenticated_request_token" do
    let(:https) { instance_double(Net::HTTP).as_null_object }
    let(:request) { instance_double(Net::HTTP::Post).as_null_object }

    before do
      allow(Net::HTTP).to receive(:new).and_return(https)
      allow(Net::HTTP::Post).to receive(:new).and_return(request)
    end

    context "correct response" do
      let(:correct_response) { double("correct_response", code: 200, body: '{"access_token": "dummy_token"}') }

      before do
        allow(https).to receive(:request).with(request).and_return(correct_response)
      end

      it "should return the access token" do
        expect(subject.authenticated_request_token).to eq "dummy_token"
      end
    end

    context "when error" do
      before do
        allow(https).to receive(:request).and_raise(Net::ReadTimeout)
      end

      it "should retry on error" do
        expect(https).to receive(:request).twice

        expect { subject.authenticated_request_token }.to raise_error(Net::ReadTimeout)
      end
    end
  end

  describe "#earnrequest" do
    context "responding with an empty body" do
      it "sends an earn request and gets an invalid http status code with empty body" do
        api_result = OpenStruct.new(
          code: 401,
          body: ""
        )
        expect { make_request_and_get_the_passed_in_api_result(api_result) }
          .to raise_error("Empty response body! HTTP status: 401")
      end

      it "sends an earn request and gets an invalid http status code with body only containing white space" do
        api_result = OpenStruct.new(
          code: 401,
          body: "\n\r\t"
        )
        expect { make_request_and_get_the_passed_in_api_result(api_result) }
          .to raise_error("Empty response body! HTTP status: 401")
      end
    end

    context "responding with a non empty body but with an error case" do
      it "sends an earnrequest and gets an invalid status code" do
        api_result = OpenStruct.new(
          code: 201,
          body: '{"status": 6}'
        )
        expected_error_message = /Miles and more error: .*/
        expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_message)
        expect { make_request_and_get_the_passed_in_api_result(api_result) }.to raise_error(expected_error_message)
      end

      it "sends an earn request and gets an invalid http status code" do
        api_result = OpenStruct.new(
          code: 405,
          body: "{}"
        )
        expected_error_message = /Miles and more error: .*/
        expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_message)
        expect { make_request_and_get_the_passed_in_api_result(api_result) }.to raise_error(expected_error_message)
      end

      it "sends an earn request and gets an invalid http status code with error code in body" do
        api_result = OpenStruct.new(
          code: 400,
          body: '{"code": 0,"message": "string"}'
        )
        expected_error_message = /Miles and more error: .*/
        expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_message)
        expect { make_request_and_get_the_passed_in_api_result(api_result) }.to raise_error(expected_error_message)
      end

      it "sends an earnrequest and gets an invalid response without code" do
        api_result = OpenStruct.new(
          code: 201,
          body: "{}"
        )
        expected_error_message = /Miles and more error: .*/
        expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_message)
        expect { make_request_and_get_the_passed_in_api_result(api_result) }.to raise_error(expected_error_message)
      end
    end

    context "successful call" do
      it "sends an earnrequest and gets a valid result" do
        api_result = OpenStruct.new(
          code: 201,
          body: '{"status": 4}'
        )
        result = make_request_and_get_the_passed_in_api_result(api_result)
        expect(result[:data]["status"]).to eq(4)
      end
    end
  end

  def make_request_and_get_the_passed_in_api_result(api_result)
    fake_post_request = instance_double(Net::HTTP::Post)
    allow(fake_post_request).to receive(:add_field)
    allow(fake_post_request).to receive(:body=)

    allow(Net::HTTP::Post).to receive(:new).and_return(fake_post_request)
    allow_any_instance_of(described_class).to receive(:authenticated_request_token).and_return(auth_token)

    client  = described_class.new
    booking = OpenStruct.new(
      transaction_text:        "transaction_text",
      mam_property_code:       "mam_property_code",
      member_alias:            "member_alias",
      miles_to_book:           "miles_to_book",
      action:                  "action",
      additional_partner_data: "additional_partner_data"
    )
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(api_result)
    result = client.earnrequest(booking)
    result
  end
end
