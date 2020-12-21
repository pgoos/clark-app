# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ahoy::MessagesController, :integration, type: :controller do
  let!(:message) { create(:ahoy_message, opened_at: opened_at, clicked_at: clicked_at) }
  let(:opened_at) { nil }
  let(:clicked_at) { nil }
  let(:params) { {id: message.token} }

  let!(:current_time) { Time.zone.now }

  before do
    allow(Time).to receive(:now).and_return(current_time)
    @routes = AhoyEmail::Engine.routes
  end

  describe "#open" do
    subject { get :open, params: params }

    context "when email was not opened yet" do
      let(:opened_at) { nil }

      it "updates opened_at timestamp and returns tracking pixel gif" do
        expect { subject }.to change { message.reload.opened_at
                                              .try(:strftime, "%Y-%m-%d %H:%M:%S") }
                                              .from(nil)
                                              .to(current_time.strftime("%Y-%m-%d %H:%M:%S"))
        expect(response.body[0..2]).to eq("GIF")
      end
    end

    context "when email was opened before" do
      let(:opened_at) { Time.zone.now - 1.day }

      it "does not update opened_at timestamp and returns tracking pixel gif" do
        expect { subject }.not_to change { message.reload.opened_at }
        expect(response.body[0..2]).to eq("GIF")
      end
    end
  end

  describe "#click" do
    subject { get :click, params: params }

    before { params.merge!(url: url, signature: signature) }
    let(:url) { "http://www.original.url" }
    let(:signature) { OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), AhoyEmail.secret_token, url) }

    context "when email link was not clicked yet" do
      let(:clicked_at) { nil }

      it "updates clicked_at timestamp and redirects to original URL" do
        expect { subject }.to change { message.reload.clicked_at.try(:strftime, "%Y-%m-%d %H:%M:%S") }.from(nil).to(current_time.strftime("%Y-%m-%d %H:%M:%S"))
        expect(response).to redirect_to("http://www.original.url")
      end
    end

    context "when email link was clicked before" do
      let(:clicked_at) { Time.now - 1.day }

      it "does not update clicked_at timestamp and redirects to original URL" do
        expect { subject }.not_to change { message.reload.clicked_at }
        expect(response).to redirect_to("http://www.original.url")
      end
    end

    context "when signature is invalid" do
      let(:clicked_at) { nil }
      let(:signature) { "invalid_signature" }

      it "updates clicked_at timestamp but redirects to root URL" do
        expect { subject }.to change { message.reload.clicked_at.try(:strftime, "%Y-%m-%d %H:%M:%S") }.from(nil).to(current_time.strftime("%Y-%m-%d %H:%M:%S"))
        expect(response).to redirect_to("http://test.host/")
      end
    end
  end
end
