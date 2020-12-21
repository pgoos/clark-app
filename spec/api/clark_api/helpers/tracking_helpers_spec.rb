# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Helpers::TrackingHelpers, :integration do
  subject { dummy_class.new(user, mandate) }

  let(:dummy_class) do
    Class.new do
      include ClarkAPI::Helpers::TrackingHelpers

      attr_reader :current_user, :current_mandate

      def initialize(current_user, current_mandate)
        @current_user = current_user
        @current_mandate = current_mandate
      end

      def env
        @env ||= Rack::MockRequest.env_for("/dummy_tracking")
      end
    end
  end

  let(:user) { nil }
  let(:mandate) { nil }

  describe "#ahoy" do
    it "builds ahoy object" do
      expect(subject.ahoy).to be_kind_of Ahoy::Tracker
      expect(subject.ahoy.request).to be_kind_of ActionDispatch::Request
    end
  end

  describe "#track_ahoy_visit" do
    it "creates a new visit" do
      expect { subject.track_ahoy_visit }.to change(Tracking::Visit, :count).by(1)
    end

    context "with mandate" do
      let(:mandate) { create(:mandate) }

      it "associates visit with mandate" do
        subject.track_ahoy_visit
        visit = Tracking::Visit.last
        expect(visit).to be_present
        expect(visit.mandate).to eq mandate
      end
    end

    context "when visit was already created" do
      before do
        subject.track_ahoy_visit
        allow(subject.ahoy).to receive(:new_visit?).and_return(false)
      end

      it "does NOT create a new visit" do
        expect { subject.track_ahoy_visit }.not_to change(Tracking::Visit, :count)
      end

      context "and there is NO visit saved in backend" do
        before do
          subject.ahoy.visit.destroy
          subject.ahoy.instance_variable_get(:@store).instance_variable_set(:@visit, nil)
          subject.ahoy.instance_variable_set(:@visit, nil)
        end

        it "creates a new visit" do
          expect { subject.track_ahoy_visit }.to change(Tracking::Visit, :count).by(1)
        end
      end
    end
  end

  describe "#current_visit" do
    it "returns current visit" do
      expect(subject.current_visit).to eq nil
      subject.track_ahoy_visit
      expect(subject.current_visit).to be_kind_of Tracking::Visit
    end
  end

  describe "#set_ahoy_cookies" do
    it "sets tracking cookies" do
      subject.set_ahoy_cookies
      expect(subject.env["action_dispatch.cookies"]["ahoy_visitor"]).to be_present
      expect(subject.env["action_dispatch.cookies"]["ahoy_visit"]).to be_present
    end
  end
end
