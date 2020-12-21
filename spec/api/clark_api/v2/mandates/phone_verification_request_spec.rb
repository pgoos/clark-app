require "rails_helper"

RSpec.describe ClarkAPI::V2::Mandates::PhoneVerificationRequest, :integration do
  let(:phone) { "+491771912227" }
  let(:user) {  create(:user) }
  let(:mandate) { create(:mandate, user: user) }
  let!(:admin) { create(:admin) }

  context "POST /api/mandates/:id/primary_phone/phonet_validation_request" do
    it "requires authentication" do
      logout
      json_post_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", phone: phone
      expect(response.status).to eq(401)
    end

    %w[015259050001 15259050001 +4915259050001 4915259050001].each do |phone|
      it "can request a phone validation passing a phone #{phone}" do
        login_as(user, scope: :user)

        json_post_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", phone: phone

        expect(response.status).to eq(201)
      end
    end

    it "return an error if no phone is passed" do
      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", phone: ""

      expect(response.status).to eq(400)
    end

    %w[
      smokeonthewater
      +11525905000
      491525905000123213
      01525905000
      0140745742
      1575790665
      3203336
    ].each do |phone|
      it "return an error if incorrect phone #{phone} is passed" do
        login_as(user, scope: :user)

        json_post_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", phone: phone

        expect(response.status).to eq(400)
      end
    end
  end

  context "DELETE /api/mandates/:id/primary_phone/phonet_validation_request" do
    it "requires authentication" do
      logout
      json_post_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", phone: phone
      expect(response.status).to eq(401)
    end

    it 'can request a phone validation passing a phone' do
      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", phone: phone

      token = Phone.primary(mandate).first.verification_token
      json_delete_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", token: token

      expect(response.status).to eq(204)
    end

    it "return an error if no valid token is passed" do
      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", phone: phone
      json_delete_v2 "/api/mandates/#{mandate.id}/primary_phone/phone_verification_request", token: "1234"

      expect(response.status).to eq(400)
    end
  end
end
