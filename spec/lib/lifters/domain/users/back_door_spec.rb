# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Users::BackDoor do
  let(:warden_double) { instance_double(Warden::Proxy) }
  let(:logger) { double(:logger, info: nil) }
  let(:admin) { build_stubbed(:admin) }

  before do
    allow(warden_double).to receive(:user).with(:admin).and_return(admin)
  end

  describe "#sign_as" do
    subject { described_class.new(warden_double, cookies, logger) }

    let(:env)     { {} }
    let(:cookies) { {} }
    let(:request) { double(:request, env: env) }
    let(:mandate) { build_stubbed(:mandate) }

    before do
      allow(warden_double).to receive(:request).and_return(request)
    end

    it "logs an action" do
      expect(logger).to receive(:info).with(/#{admin.id}.*#{mandate.id}/)
      subject.sign_as(mandate)
    end

    it "sets request env variable" do
      subject.sign_as(mandate)
      expect(env["devise.skip_trackable"]).to eq false
    end

    it "sets cookies" do
      subject.sign_as(mandate)
      expect(cookies["signed-as"]).to eq mandate.id
    end
  end

  describe "#active_backdoor?" do
    context "when user is admin and cookie is present" do
      it "has an active backdoor" do
        cookies = {described_class::SIGNED_AS_COOKIE => 1}

        active = described_class.new(warden_double, cookies).active_backdoor?
        expect(active).to be_present
      end
    end

    context "when the cookie is empty" do
      it "is not active" do
        allow(warden_double).to receive(:user).with(:admin).and_return(admin)
        cookies = {}

        active = described_class.new(warden_double, cookies).active_backdoor?
        expect(active).not_to be_present
      end
    end

    context "when the user is not logged in as admin" do
      let(:admin) { nil }

      it "is not active when the user is not logged in as admin" do
        allow(warden_double).to receive(:user).with(:admin).and_return(nil)
        cookies = {described_class::SIGNED_AS_COOKIE => 1}

        active = described_class.new(warden_double, cookies).active_backdoor?
        expect(active).not_to be_present
      end
    end
  end
end
