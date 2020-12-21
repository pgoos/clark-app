# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account::InsignConfigurationHelper do
  subject { Account::MandatesHelper }

  let(:resource) { build :mandate }
  let(:insign_session_id) { "insign_session_id_string" }
  let(:params) do
    {
      width: "328px",
      height: "170px",
      variation: "variation_string"
    }
  end

  let(:insign_base_url) { Insign::BASE_URL }

  before do
    allow(SignatureService).to receive(:upload_empty_mandate_pdf_to_insign).and_return(insign_session_id)
  end

  describe "#define_callback_parameters" do
    it "setup 'width' instance variable" do
      define_callback_parameters

      expect(@width).to eq(params[:width])
    end

    it "setup 'height' instance variable" do
      define_callback_parameters

      expect(@height).to eq(params[:height])
    end

    it "setup 'variation' instance variable" do
      define_callback_parameters

      expect(@variation).to eq(params[:variation])
    end

    it "setup 'session_id' instance variable" do
      define_callback_parameters

      expect(@session_id).to eq(insign_session_id)
    end

    it "setup 'insign_base_url' instance variable" do
      define_callback_parameters

      expect(@insign_base_url).to eq(insign_base_url)
    end
  end

  describe "#define_callback_api_endpoint" do
    let(:session) { {"_csrf_token" => "csrf_token_string"}.with_indifferent_access }
    let(:callback_api2_version) { ClarkAPI::V2::Root::API_VERSION_HEADER }
    let(:callback_api5_version) { ClarkAPI::V5::Root::API_VERSION_HEADER }
    let(:callback_v2_method) { "GET" }
    let(:callback_v5_method) { "POST" }
    let(:callback_api_v2_url) { "/api/mandates/#{resource.id}/insign_success/#{insign_session_id}" }
    let(:callback_api_v5_url) { "/api/customer/upgrade_journey/confirm_signature" }

    before do
      @session_id = insign_session_id
    end

    context "customer_state is nil" do
      it "setup 'callback_method' instance variable" do
        define_callback_api_endpoint

        expect(@callback_method).to eq(callback_v2_method)
      end

      it "setup 'callback_api' instance variable" do
        define_callback_api_endpoint

        expect(@callback_api).to eq(callback_api_v2_url)
      end

      it "setup 'callback_api_version' instance variable" do
        define_callback_api_endpoint

        expect(@callback_api_version).to eq(callback_api2_version)
      end

      it "does not setup 'insign_session_id' instance variable" do
        define_callback_api_endpoint

        expect(@insign_session_id).to be_nil
      end

      it "does not setup 'csrf_token' instance variable" do
        define_callback_api_endpoint

        expect(@csrf_token).to be_nil
      end
    end

    context "customer_state is NOT nil" do
      before do
        resource.customer_state = "prospect"
      end

      it "setup 'callback_method' instance variable" do
        define_callback_api_endpoint

        expect(@callback_method).to eq(callback_v5_method)
      end

      it "setup 'callback_api' instance variable" do
        define_callback_api_endpoint

        expect(@callback_api).to eq(callback_api_v5_url)
      end

      it "setup 'callback_api_version' instance variable" do
        define_callback_api_endpoint

        expect(@callback_api_version).to eq(callback_api5_version)
      end

      it "setup 'insign_session_id' instance variable" do
        define_callback_api_endpoint

        expect(@insign_session_id).to eq(insign_session_id)
      end

      it "setup 'csrf_token' instance variable" do
        define_callback_api_endpoint

        expect(@csrf_token).to eq(session["_csrf_token"])
      end
    end
  end
end
