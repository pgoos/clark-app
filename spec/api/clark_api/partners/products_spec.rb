# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::Products, :integration do
  let(:endpoint) { "/api/products" }

  before do
    @file     = fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
    @client   = create(:api_partner)
    @client.save_secret_key!("raw")
    @client.update_access_token_for_instance!("test")
    @access_token = @client.access_token_for_instance("test")["value"]
  end

  describe "POST /api/products" do
    it_behaves_like "unathorized endpoint of the partnership api"

    before do
      mandate  = create(:mandate, owner_ident: @client.partnership_ident)
      @plan    = create(:plan)
      @params  = {
        product: {
          mandate_id:          mandate.id,
          plan_ident:          @plan.ident,
          number:              Faker::Code.asin,
          contract_started_at: Faker::Date.forward(days: 30),
          renewal_period:      Faker::Number.between(from: 1, to: 12),
          annual_maturity:     "00-00"
        }
      }
    end

    context "when required param is missing" do
      before do
        partners_post endpoint, headers: {"Authorization" => @access_token}
      end

      it "returns 400 http status" do
        expect(response.status).to eq(400)
      end

      it "returns the error object" do
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end

    context "when all required params are valid" do
      before do
        partners_post endpoint, payload_hash: @params,
                                 headers:      {"Authorization" => @access_token}
      end

      it "returns 201" do
        expect(response.status).to eq(201)
      end

      it "returns the product object" do
        expect(response.body).to match_response_schema("partners/20170213/product")
      end

      it "creates a product with price and period taken from the plan" do
        product = JSON.parse(response.body)["product"]

        expect(product["premium_price_cents"]).to eq(@plan.premium_price_cents)
        expect(product["premium_price_currency"]).to eq(@plan.premium_price_currency)
        expect(product["premium_period"]).to eq(@plan.premium_period)
      end
    end

    context "when gkv product" do
      let(:gkv_plan) { create(:plan_gkv) }
      let(:product) { JSON.parse(response.body)["product"] }

      before do
        @params[:product][:plan_ident] = gkv_plan.ident
        allow(Settings).to receive_message_chain("categories.gkv.enabled").and_return setting
        partners_post endpoint, payload_hash: @params,
                                headers: {Authorization: @access_token}
      end

      context "and categories.gkv.enabled setting is turned on" do
        let(:setting) { true }

        it "should contains gkv_price_percentage attribute in response" do
          expect(product["gkv_price_percentage"]).to eq(7.45)
        end
      end

      context "and categories.gkv.enabled setting is turned off" do
        let(:setting) { false }

        it "should not contain gkv_price_percentage attribute in response" do
          expect(product["gkv_price_percentage"]).to be(nil)
        end
      end
    end

    context "the endpoint is idempotent" do
      before do
        2.times do
          partners_post endpoint, payload_hash: @params.merge(policy_document: @file),
                                   headers:      {"Authorization" => @access_token},
                                   json:         false
        end
      end

      it "returns 200 http status" do
        expect(response.status).to eq(200)
      end

      it "returns the existing product object" do
        expect(response.body).to match_response_schema("partners/20170213/product")
      end
    end

    context "setting the `contract_ended_at` field" do
      before do
        @contract_ended_at    = Time.zone.now + 1.year
        @params_with_end_date = @params.dup

        @params_with_end_date[:product][:plan_ident] = create(:plan).ident
        @params_with_end_date[:product][:number]     = Faker::Code.asin
        @params_with_end_date[:product].merge!(contract_ended_at: @contract_ended_at,
                                               testing_mode:      true)
      end

      it "saves the value only for testing" do
        partners_post endpoint, payload_hash: @params_with_end_date,
                                 headers:      {"Authorization" => @access_token}

        product = JSON.parse(response.body)["product"]

        expect(response.status).to eq(201)
        expect(Time.parse(product["contract_ended_at"]).in_time_zone.strftime("%d/%m/%Y %H:%M"))
          .to eq(@contract_ended_at.strftime("%d/%m/%Y %H:%M"))
      end

      it "doesn't save the value in usual mode" do
        @params_with_end_date[:product][:testing_mode] = false

        partners_post endpoint, payload_hash: @params_with_end_date,
                                 headers:      {"Authorization" => @access_token}

        product = JSON.parse(response.body)["product"]

        expect(response.status).to eq(201)
        expect(product[:contract_ended_at]).to eq(nil)
      end

      it "rejects the request in production environment" do
        allow(Rails.env).to receive(:production?).and_return(true)

        partners_post endpoint, payload_hash: @params_with_end_date,
                                headers:      {"Authorization" => @access_token}

        expect(response.status).to eq(405)
      end
    end
  end
end
