# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Passwords, :integration do
  let(:user) { create(:user, :with_mandate) }

  describe "POST /api/passwords/forgot" do
    let(:params) { {email: user.email} }
    let(:params_wrong) { {email: "nonexistent@blah.de"} }

    context "when user is found" do
      it "it sends password forgot email" do
        expect {
          json_post_v4("/api/passwords/forgot", params)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(response.status).to eq(201)
      end
    end

    context "when user not found" do
      it "returns 404 error" do
        json_post_v4("/api/passwords/forgot", params_wrong)
        expect(response.status).to eq(404)
        expect(json_response.error)
          .to eq(I18n.t("grape.errors.messages.email_not_found"))
      end
    end
  end
end
