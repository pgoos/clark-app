# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, :integration, type: :controller do
  let(:cookie_key) { TrackingController::OPT_OUT_TRACKING_COOKIE }

  before do
    routes.draw { get "dummy" => "application#index" }
  end

  after { Rails.application.reload_routes! }

  describe "#authenticate!" do
    context "basic auth is disabled" do
      it "should not set basic auth" do
        expect(controller).not_to receive(:authenticate_or_request_with_http_basic)

        subject.send(:authenticate!)
      end
    end

    context "basic auth is enabled" do
      before do
        allow(ENV).to receive(:fetch).with("BASICAUTH_USER", "").and_return("test")
        allow(ENV).to receive(:fetch).with("BASICAUTH_PASS", "").and_return("test")
      end

      context "Android debug apps" do
        it "should authenticate with user-agent" do
          allow(request).to receive(:user_agent).and_return \
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko)\
            Chrome/67.0.3396.99 Safari/537.36 Android w2sjbt7znh"

          expect(controller).not_to receive(:authenticate_or_request_with_http_basic)

          subject.send(:authenticate!)
        end

        it "should authenticate fail without android user-agent" do
          expect(controller).to receive(:authenticate_or_request_with_http_basic)

          subject.send(:authenticate!)
        end
      end

      context "Ios debug apps" do
        it "should authenticate with user-agent" do
          allow(request).to receive(:user_agent).and_return \
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko)\
            Chrome/67.0.3396.99 Safari/537.36 Ios ut8fg9o7iu"

          expect(controller).not_to receive(:authenticate_or_request_with_http_basic)

          subject.send(:authenticate!)
        end

        it "should authenticate fail without ios user-agent" do
          expect(controller).to receive(:authenticate_or_request_with_http_basic)

          subject.send(:authenticate!)
        end
      end

      context "Salesforce" do
        it "should not set basic auth" do
          allow(request).to receive(:path).and_return("/api/callbacks/v1/salesforce/stop")
          expect(controller).not_to receive(:authenticate_or_request_with_http_basic)

          subject.send(:authenticate!)
        end
      end

      context "Cucumber automation" do
        it "should not set basic auth" do
          allow(request).to receive(:user_agent).and_return \
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko)\
            Chrome/67.0.3396.99 Safari/537.36, Cucumber 2154a52c"
          expect(controller).not_to receive(:authenticate_or_request_with_http_basic)

          subject.send(:authenticate!)
        end

        it "should authenticate fail without cucumber user-agent" do
          expect(controller).to receive(:authenticate_or_request_with_http_basic)

          subject.send(:authenticate!)
        end
      end

      context "normal browser" do
        it "should set basic auth" do
          allow(ENV).to receive(:fetch).with("BASICAUTH_USER", "").and_return("test")
          allow(ENV).to receive(:fetch).with("BASICAUTH_PASS", "").and_return("test")
          expect(controller).to receive(:authenticate_or_request_with_http_basic)
          subject.send(:authenticate!)
        end

        it "should NOT set basic auth" do
          allow(ENV).to receive(:fetch).with("BASICAUTH_USER", "").and_return("")
          allow(ENV).to receive(:fetch).with("BASICAUTH_PASS", "").and_return("")
          expect(controller).not_to receive(:authenticate_or_request_with_http_basic)
          subject.send(:authenticate!)
        end
      end
    end
  end

  describe "#authenticate_session_for_lead_if_requested" do
    before do
      allow(controller).to receive(:params).and_return(restoration_token: "1234")
      expect(::Platform::LeadSessionRestoration).to receive(:decrypt_restoration_token).with("1234").and_return("1234")
    end

    context "when the url has the params matching with the lead restoration token" do
      let!(:lead) { create(:lead, restore_session_token: "1234") }

      it "the session is restored with the lead corresponding to the params" do
        expect(request.env["warden"]).to receive(:set_user).with(lead, any_args)
        subject.send(:authenticate_session_for_lead_if_params_present)
      end
    end

    context "when the url has params with not lead matching with the restoration token" do
      let!(:lead) { create(:lead, restore_session_token: "12342344") }

      it "the session is not restored since no lead found" do
        expect(request.env["warden"]).not_to receive(:set_user).with(lead, any_args)
        subject.send(:authenticate_session_for_lead_if_params_present)
      end
    end
  end

  describe "#add_admin_context" do
    it "sets request flag admin_context to true if the request url includes /admin" do
      allow(request).to receive(:url).and_return("host_url/admin/extra")
      subject.send(:add_admin_context)
      expect(request[:admin_context]).to be_truthy
    end

    it "set request flag admin_context to flag if the request url does not include /admin" do
      allow(request).to receive(:url).and_return("host_url/extra")
      subject.send(:add_admin_context)
      expect(request[:admin_context]).to be_falsey
    end
  end
end
