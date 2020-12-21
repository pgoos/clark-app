# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe Ahoy::Store do
  before do
    allow(controller).to receive(:request).and_return(empty_request)
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:current_lead).and_return(current_lead)
    ahoy_store.instance_variable_set(:@user, current_user)
  end

  let(:controller) { Ahoy::EventsController.new }
  let(:current_user) { nil }
  let(:current_lead) { nil }
  let(:ahoy_tracker) { Ahoy::Tracker.new(controller: controller) }
  let(:ahoy_store) { ahoy_tracker.instance_variable_get(:@store) }
  let(:empty_env) { {"warden" => double(user: nil)} }
  let(:empty_request) { OpenStruct.new(headers: {}, cookies: {}, params: {}, env: empty_env) }
  let(:visit_token) { "c1b6324a-bcb4-4ce8-b44c-88493f4d912a" }
  let(:visitor_token) { "668337f0-8707-426b-a797-adcb5348640e" }

  describe "#exclude?" do
    subject { described_class.new(options) }

    let(:options)    { { request: request } }
    let(:request)    { double(:request, headers: headers, user_agent: user_agent, path: path) }
    let(:headers)    { { "User-Agent" => user_agent } }
    let(:user_agent) { "" }
    let(:path)       { "" }

    context "with user_agent" do
      context "when okhttp" do
        let(:user_agent) { "okhttp/3.4.1" }

        it { expect(subject).to be_exclude }
      end

      context "when bot" do
        let(:user_agent) { "Googlebot-Image/1.0" }

        it { expect(subject).to be_exclude }

        context "when minibot" do
          let(:user_agent) { "Monibot" }

          it { expect(subject).to be_exclude }
        end

        context "when adbeat" do
          let(:user_agent) { "adbeat_bot" }

          it { expect(subject).to be_exclude }
        end

        context "when coccocbot" do
          let(:user_agent) { "coccocbot" }

          it { expect(subject).to be_exclude }
        end

        context "when rytebot" do
          let(:user_agent) { "RyteBot" }

          it { expect(subject).to be_exclude }
        end

        context "when petalbot" do
          let(:user_agent) { "PetalBot" }

          it { expect(subject).to be_exclude }
        end
      end

      context "when Go-http-client" do
        let(:user_agent) { "Go-http-client/1.1" }

        it { expect(subject).to be_exclude }
      end

      context "when prometheus" do
        let(:user_agent) { "Prometheus/1.0" }

        it { expect(subject).to be_exclude }
      end

      context "when wkhtmltopdf" do
        let(:user_agent) {
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/538.1 (KHTML, like Gecko) wkhtmltopdf Safari/538.1"
        }

        it { expect(subject).to be_exclude }
      end

      context "when wkhtmltoimage" do
        let(:user_agent) {
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/538.1 (KHTML, like Gecko) wkhtmltoimage Safari/538.1"
        }

        it { expect(subject).to be_exclude }
      end

      context "when desktop browser" do
        let(:user_agent) {
          "Mozilla/5.0 (Linux; Android 10; LM-V350) AppleWebKit/537.36 " \
            "(KHTML, like Gecko) Chrome/85.0.4183.47 Mobile Safari/537.36"
        }

        it { expect(subject).not_to be_exclude }
      end

      context "when mobile" do
        let(:user_agent) {
          "Mozilla/5.0 (Linux; Android 9; SM-J530GM) AppleWebKit/537.36 " \
            "(KHTML, like Gecko) Chrome/83.0.4103.106 Mobile Safari/537.36"
        }

        it { expect(subject).not_to be_exclude }
      end
    end

    context "with path" do
      context "when tracking" do
        let(:path) { "/tracking/adjust/event" }

        it { expect(subject).to be_exclude }
      end

      context "when admin" do
        let(:path) { "/admin" }

        it { expect(subject).to be_exclude }
      end

      context "with heartbeat" do
        let(:path) { "/heartbeat" }

        it { expect(subject).to be_exclude }
      end

      context "with wp" do
        let(:path) { "/de/wp-login.php" }

        it { expect(subject).to be_exclude }
      end

      context "with sbot_messages" do
        let(:path) { "/de/sbot_messages" }

        it { expect(subject).to be_exclude }
      end

      context "with cms" do
        let(:path) { "/cms-css/" }

        it { expect(subject).to be_exclude }
      end

      context "with app feed" do
        let(:path) { "/app/feed" }

        it { expect(subject).to be_exclude }
      end

      context "with rails/active_storage/blobs" do
        let(:path) { "/rails/active_storage/blobs" }

        it { expect(subject).to be_exclude }
      end

      context "with ahoy messages" do
        let(:path) { "/de/ahoy/messages" }

        it { expect(subject).to be_exclude }
      end

      context "with other path" do
        let(:path) { "/app" }

        it { expect(subject).not_to be_exclude }
      end
    end
  end

  describe "tracking visits" do
    subject { successfully_created_visit }

    def successfully_created_visit
      expect { track_visit }.to change { Tracking::Visit.count }.by(1)
      Tracking::Visit.last
    end

    def track_visit
      ahoy_store.track_visit({visit_token: visit_token, visitor_token: visitor_token})
    end

    context "when controller knows no user" do
      let(:current_user) { nil }

      it "stores a tracking visit without user" do
        expect(subject.mandate).to be(nil)
      end
    end

    context "when controller knows a user with mandate" do
      let(:current_user) { create(:user, :with_mandate) }

      it "stores a tracking visit with associated mandate" do
        expect(subject.mandate).to eq(current_user.mandate)
      end
    end

    context "when controller knows a lead with mandate" do
      let(:current_lead) { create(:lead, :with_mandate) }

      it "stores a tracking visit with associated mandate" do
        expect(subject.mandate).to eq(current_lead.mandate)
      end
    end
  end

  describe "tracking events" do
    subject { successfully_created_event }

    let(:event_id) { "f7279aa9-4883-4ee2-9fcc-508f5d3d1753" }
    let(:event_data) { {event_id: event_id, name: "some_event", properties: {}, visit_token: visit_token} }

    def successfully_created_event
      expect { track_event }.to change { Tracking::Event.count }.by(1)
      Tracking::Event.last
    end

    def track_event
      ahoy_store.track_visit({visit_token: visit_token, visitor_token: visitor_token})
      ahoy_store.track_event(event_data)
    end

    context "when controller knows no mandate" do
      let(:current_user) { nil }

      it "stores a tracking event without mandate" do
        expect(subject.mandate).to be(nil)
      end
    end

    context "visit has no mandate info but event has" do

      let(:current_user) { create(:user, :with_mandate) }

      before do
        # First nil called by track_visit second is for track_event
        # Thus, we can reproduce visit has no mandate but event has it
        allow(ahoy_store).to receive(:mandate).and_return(nil, current_user.mandate)
      end

      it "should update the associated visit with the current mandate" do
        associated_visit = ahoy_store.track_visit(visit_token: visit_token, visitor_token: visitor_token)
        expect(associated_visit.mandate).to be_nil
        ahoy_store.track_event(event_data)
        expect(Tracking::Visit.last.mandate).to eq(current_user.mandate)
      end
    end

    context "when controller knows a user with mandate" do
      let(:current_user) { create(:user, :with_mandate) }

      it "stores a tracking event with associated mandate" do
        expect(subject.mandate).to eq(current_user.mandate)
      end
    end

    context "when controller knows a lead with mandate" do
      let(:current_lead) { create(:lead, :with_mandate) }

      it "stores a tracking event with associated mandate" do
        expect(subject.mandate).to eq(current_lead.mandate)
      end
    end
  end

  describe ".add_sovendus_mapped_params" do
    let(:channel) { "test_channel" }
    let(:sovReqToken) { "123456" }
    let(:ahoy_data) do
      {
        landing_page: "https://clark.de?channel=#{channel}&sovReqToken=#{sovReqToken}",
        utm_source: "",
        utm_content: ""
      }
    end
    let(:subject) { ahoy_store.send(:add_sovendus_mapped_params, ahoy_data) }

    context "utm_source" do
      it "maps channel to utm_source if utm_source is empty" do
        mapped_data = subject
        expect(mapped_data[:utm_source]).to eq(channel)
      end

      it "doesn't map the channel to utm_source if it is not empty" do
        utm_source = "not empty"
        utm_source_ahoy_data = {
          landing_page: "https://clark.de?channel=#{channel}&sovReqToken=#{sovReqToken}",
          utm_source: utm_source,
          utm_content: ""
        }

        mapped_data = ahoy_store.send(:add_sovendus_mapped_params, utm_source_ahoy_data)
        expect(mapped_data[:utm_source]).to eq(utm_source)
      end
    end

    context "utm_content" do
      it "maps the sovendus request token to utm_content" do
        mapped_data = subject
        expect(mapped_data[:utm_content]).to eq(sovReqToken)
      end
    end
  end

  describe 'sanitize html' do

    context 'make tracking pixel useless' do

      html_part = <<~EOHTML
        </center>
        <img src="http://staging.clark.de/ahoy/messages/j6pajzwe7Qo9FEkBYumWEZRBNKrIZDoc/open.gif" width="1" height="1" style="height: auto; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; border: 0;">
        </body>
      EOHTML

      html_part_expected = <<~CLEANHTML
        </center>

        </body>
      CLEANHTML

      let(:sanitized) { Ahoy.cleanup_tracking_code(html_part) }

      it 'removed the pixel' do

        expect(sanitized).to eq(html_part_expected)
      end
    end
  end
end
