# frozen_string_literal: true

RSpec.shared_examples "response_methods" do
  context "when the response is successful" do
    before { request.call }

    it { expect(request).to be_response_successful }
    it { expect(request).to be_response_body_processable }

    it "response error code should be nil" do
      expect(request.response_error_code).to be_nil
    end

    it "http code of response should be 200" do
      expect(request.response_http_code).to eq(200)
    end

    it "should return body of response with associated keys" do
      expect(request.response_body.count).not_to be_zero
    end
  end

  context "when there is a http fault" do
    let(:http_response) { HTTPI::Response.new(500, {}, "") }
    let(:savon_response) { Savon::Response.new(http_response, {}, {}) }

    before do
      allow_any_instance_of(Payback::Outbound::Mocks::FakeClient)
        .to receive(:call).and_return(savon_response)

      request.call
    end

    it { expect(request).not_to be_response_successful }

    it "http code of response should be the failed http status" do
      expect(request.response_http_code).to eq(http_response.code)
    end
  end

  context "when there is an error code from payback api" do
    before do
      allow_any_instance_of(Payback::Outbound::Mocks::FakeResponse)
        .to receive(:check_for_authentication).and_return(false)

      request.call
    end

    it { expect(request).not_to be_response_successful }
    it { expect(request).to be_response_body_processable }

    it "error response code should be same with the one from payback api" do
      expect(request.response_error_code).to eq(Payback::Outbound::Mocks::FakeResponse::ERROR_CODE)
    end

    it "should return body of response with associated keys" do
      expect(request.response_body.count).not_to be_zero
    end
  end

  context "when there is a sucessful response but with not a soap right format" do
    let(:http_response) { HTTPI::Response.new(200, {}, "A dummy text") }
    let(:savon_response) { Savon::Response.new(http_response, {}, {}) }

    before do
      allow_any_instance_of(Payback::Outbound::Mocks::FakeClient)
        .to receive(:call).and_return(savon_response)

      request.call
    end

    it { expect(request).not_to be_response_successful }

    it "http code of response should be 200" do
      expect(request.response_http_code).to eq(http_response.code)
    end

    it "error response code should describe that body is unprocessable" do
      expect(request.response_error_code).to eq(Payback::Outbound::Requests::Request::UNPROCESSABLE_RESPONSE_CODE)
    end
  end

  describe "#points_amount_on_response" do
    context "when the promotion is active for transaction" do
      let(:total_points) { 750 } # Note: this is directly dependent on the xml response files in xml_responses dir

      before do
        stub_const("Payback::Outbound::Mocks::FakeResponse::PROMOTION_ACTIVE", true)
      end

      it "points amount should be the total of transactions" do
        request.call
        expect(request.points_amount_on_response).to eq total_points
      end
    end

    context "when the promotion is not active for transaction" do
      let(:total_points) { 250 } # Note: this is directly dependent on the xml response files in xml_responses dir

      before do
        stub_const("Payback::Outbound::Mocks::FakeResponse::PROMOTION_ACTIVE", false)
      end

      it "points amount should be the total of transactions" do
        request.call
        expect(request.points_amount_on_response).to eq total_points
      end
    end
  end
end
