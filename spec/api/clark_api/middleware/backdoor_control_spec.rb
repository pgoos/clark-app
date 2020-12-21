# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Middleware::BackdoorControl do
  let(:double_warden) { double("Warden::Proxy") }
  let(:dummy_app) { proc { [200, { "Content-Type" => "application/json" }, ["OK"]] } }
  let(:middleware) { described_class.new(dummy_app, {}) }

  before do
    allow(double_warden).to receive(:user).with(:admin).and_return(admin)
  end

  describe "#call" do
    let(:admin) { Admin.new }

    context "when action is not allowed" do
      let(:expected_response) { [403, { "Content-Type" => "application/json" }, [{ message: "forbidden" }.to_json]] }

      it "returns expected response" do
        %w[
          /offer/1000/accept/1001
          /offer/someID/accept/someOtherID
          /customer/upgrade_journey/confirm_signature
          /mandates/10/insign_success/1q2w3e4r5t6y
          /offer/232561/select_as_active
        ].each do |path|
          response = middleware.call({ "PATH_INFO" => path, "warden" => double_warden })
          expect(response).to eq(expected_response)
        end
      end
    end

    context "when action is allowed" do
      it "returns expected response" do
        %w[
          /current_user
          /settings
        ].each do |path|
          response = middleware.call({ "PATH_INFO" => path, "warden" => double_warden })
          expect(response).to eq(dummy_app.call)
        end
      end
    end

    context "when action is not allowed, but it's user" do
      let(:admin) { nil }
      let(:double_warden) { double(user: false) }

      it "returns expected response" do
        %w[
          /offer/1000/accept/1001
          /offer/someID/accept/someOtherID
          /customer/upgrade_journey/confirm_signature
          /mandates/10/insign_success/1q2w3e4r5t6y
          /offer/232561/select_as_active
        ].each do |path|
          response = middleware.call({ "PATH_INFO" => path, "warden" => double_warden })
          expect(response).to eq(dummy_app.call)
        end
      end
    end
  end
end
