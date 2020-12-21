# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::Testing, :integration do
  before :all do
    @endpoint = "/api/testing"
    @client   = create(:api_partner)
    @client.save_secret_key!("raw")
    @client.update_access_token_for_instance!("test")
    @access_token = @client.access_token_for_instance("test")["value"]
  end

  before do
    allow(Features).to receive(:active?).and_return(true)
    allow(Features).to receive(:active?).with("API_NOTIFY_PARTNERS").and_return(false)
  end

  context "switched feature" do
    before do
      allow(Features).to receive(:active?).and_return(false)
    end

    it "restricts the access and returns 405 status code" do
      partners_delete "#{@endpoint}/mandates/0"
      expect(response.status).to eq(405)
    end
  end

  context "delete mandate" do
    it "returns 204" do
      mandate = create(:mandate, owner_ident: @client.partnership_ident)

      partners_delete "#{@endpoint}/mandates/#{mandate.id}",
                      headers: {"Authorization" => @access_token}

      expect(response.status).to eq(204)
    end
  end

  # NOTE: because next methods just change the entity state and model specs test state machine
  #       transitions, we don't need to test it below. HTTP calls specs are enough.

  context "change the mandate state" do
    before do
      user     = create(:user)
      @mandate = create(:mandate, user: user, owner_ident: @client.partnership_ident)
    end

    it "returns 200" do
      partners_put "#{@endpoint}/mandates/#{@mandate.id}",
                   headers:      {"Authorization" => @access_token},
                   payload_hash: {action: "complete"}

      expect(response.status).to eq(200)
    end

    not_allowed_mandate_states = Mandate.state_machine.events.map(&:name) -
                                   described_class::ALLOWED_MANDATE_ACTIONS

    not_allowed_mandate_states.each do |not_allowed_state|
      it "returns 405 when `#{not_allowed_state}` action is not allowed" do
        partners_put "#{@endpoint}/mandates/#{@mandate.id}",
                     headers:      {"Authorization" => @access_token},
                     payload_hash: {action: not_allowed_state}

        expect(response.status).to eq(405)
      end
    end
  end

  context "change the inquiry_category state" do
    before do
      user      = create(:user)
      mandate   = create(:mandate, user: user, owner_ident: @client.partnership_ident)
      category  = create(:category)
      @inquiry  = create(:inquiry, mandate: mandate, categories: [category])
    end

    it "returns 200" do
      partners_put "#{@endpoint}/inquiry_categories/#{@inquiry.inquiry_categories.first.id}",
                   headers:      {"Authorization" => @access_token},
                   payload_hash: {action: "accept"}

      expect(response.status).to eq(200)
    end

    not_allowed_inquiry_states = Inquiry.state_machine.events.map(&:name) -
                                   described_class::ALLOWED_INQUIRY_ACTIONS

    not_allowed_inquiry_states.each do |not_allowed_state|
      it "returns 405 when `#{not_allowed_state}` action is not allowed" do
        partners_put "#{@endpoint}/inquiry_categories/#{@inquiry.inquiry_categories.first.id}",
                     headers:      {"Authorization" => @access_token},
                     payload_hash: {action: not_allowed_state}

        expect(response.status).to eq(405)
      end
    end
  end

  context "change the product state" do
    before do
      user     = create(:user)
      mandate  = create(:mandate, user: user, owner_ident: @client.partnership_ident)
      @product = create(:product, mandate: mandate)
    end

    it "returns 200" do
      partners_put "#{@endpoint}/products/#{@product.id}",
                   headers:      {"Authorization" => @access_token},
                   payload_hash: {action: "request_takeover"}

      expect(response.status).to eq(200)
    end

    not_allowed_product_states = Product.state_machine.events.map(&:name) -
                                   described_class::ALLOWED_PRODUCT_ACTIONS

    not_allowed_product_states.each do |not_allowed_state|
      it "returns 405 when `#{not_allowed_state}` action is not allowed" do
        partners_put "#{@endpoint}/products/#{@product.id}",
                     headers:      {"Authorization" => @access_token},
                     payload_hash: {action: not_allowed_state}

        expect(response.status).to eq(405)
      end
    end
  end

  context "create product advice" do
    let(:mandate) { create(:mandate, owner_ident: @client.partnership_ident) }
    let!(:product) { create(:product, mandate: mandate) }
    let!(:admin) { create(:admin) }
    let(:valid_payload) { {content: "advice content"} }

    it "returns 201 when advice can be created successfully" do
      partners_post "#{@endpoint}/products/#{product.id}/advices",
                    headers: {"Authorization" => @access_token},
                    payload_hash: valid_payload

      expect(response.status).to eq(201)
    end

    it "returns not found if non existing product id is passed" do
      partners_post "#{@endpoint}/products/12345678/advices",
                    headers: {"Authorization" => @access_token},
                    payload_hash: valid_payload

      expect(response.status).to eq(404)
    end

    it "returns bad request code if content is not passed as a param" do
      partners_post "#{@endpoint}/products/#{product.id}/advices",
                    headers: {"Authorization" => @access_token},
                    payload_hash: {}

      expect(response.status).to eq(400)
    end
  end
end
