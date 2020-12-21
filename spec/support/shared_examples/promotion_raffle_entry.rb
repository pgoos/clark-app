# frozen_string_literal: true

RSpec.shared_examples "promotion raffle entry" do
  def submit_entry
    login_as(user_resource, scope: user_type)
    json_put_v4 "/api/mandates/#{mandate.id}/promotion_raffle", params
    user_resource.reload
  end

  it "should be valid when all mandatory params present" do
    submit_entry
    expect(response.status).to eq 200
  end

  it "correctly updates mandate id" do
    submit_entry
    expect(json_response.mandate.id).to eq(mandate.id)
  end

  it "correctly updates first name" do
    submit_entry
    expect(json_response.mandate.first_name).to eq(params[:first_name])
  end

  it "correctly updates last name" do
    submit_entry
    expect(json_response.mandate.last_name).to eq(params[:last_name])
  end

  it "correctly updates gender" do
    submit_entry
    expect(json_response.mandate.gender).to eq(params[:gender])
  end

  it "correctly updates birthdate" do
    submit_entry
    expect(Time.zone.parse(json_response.mandate.birthdate))
      .to eq(Time.zone.parse(params[:birthdate]))
  end

  it "correctly updates last name" do
    submit_entry
    expect(json_response.mandate.last_name).to eq(params[:last_name])
  end

  it "correctly updates gender" do
    submit_entry
    expect(json_response.mandate.gender).to eq(params[:gender])
  end

  it "correctly updates birthdate" do
    submit_entry
    expect(Time.zone.parse(json_response.mandate.birthdate))
      .to eq(Time.zone.parse(params[:birthdate]))
  end

  it "correctly updates promotion_raffle_identifier" do
    user_resource = submit_entry
    expect(user_resource.customer_related["promotion_raffle_identifier"])
      .to eq(params[:promotion_identifier])
  end

  it "correctly updates promotion_raffle_percentage" do
    user_resource = submit_entry
    expect(user_resource.customer_related["promotion_raffle_percentage"])
      .to eq(params[:promotion_raffle_percentage])
  end

  it "correctly updates promotion_raffle_products_count" do
    user_resource = submit_entry
    expect(user_resource.customer_related["promotion_raffle_products_count"]).to eq(params[:insurances])
  end

  it "correctly updates promotion_raffle_terms_accepted_at" do
    user_resource = submit_entry
    expect(user_resource.customer_related["promotion_raffle_terms_accepted_at"]).not_to be_empty
  end

  it "correctly updates utm_source" do
    user_resource = submit_entry
    expect(user_resource.source_data["adjust"]["network"]).to eq(params[:tracking][:utm_source])
  end

  it "correctly updates utm_term" do
    user_resource = submit_entry
    expect(user_resource.source_data["adjust"]["creative"]).to eq(params[:tracking][:utm_term])
  end

  it "correctly updates utm_content" do
    user_resource = submit_entry
    expect(user_resource.source_data["adjust"]["adgroup"]).to eq(params[:tracking][:utm_content])
  end

  it "correctly updates utm_campaign" do
    user_resource = submit_entry
    expect(user_resource.source_data["adjust"]["campaign"]).to eq(params[:tracking][:utm_campaign])
  end

  it "correctly updates utm_medium" do
    user_resource = submit_entry
    expect(user_resource.source_data["adjust"]["medium"]).to eq(params[:tracking][:utm_medium])
  end

  it "correctly updates utm_landing_page" do
    user_resource = submit_entry
    expect(user_resource.source_data["utm_landing_page"]).to eq(params[:tracking][:utm_landing_page])
  end

  context "when params are missing" do
    let(:params) { nil }

    it "returns presence validation error 400" do
      submit_entry
      expect(response.status).to eq 400
    end
  end

  context "when optional tracking params are missing" do
    let(:params) { put_params.merge(tracking: {}) }

    it "should still be able to enter the raffle" do
      submit_entry
      expect(response.status).to eq 200
    end
  end

  context "that has not consented to receive further emails" do
    let(:params) { put_params.merge(consent: false) }

    it "should still be able to enter the raffle" do
      submit_entry
      expect(response.status).to eq 200
    end
  end
end
