# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account::BaseHelper, :integration do
  subject { AccountBaseHelperDummy.new(warden_double) }

  before :all do
    class AccountBaseHelperDummy
      include Account::BaseHelper

      attr_accessor :cookies

      def initialize(warden_double, cookies={})
        @env_double = {"warden" => warden_double}
        @cookies = cookies
      end

      def env
        @env_double
      end

      def request
        ActionController::TestRequest.new(@env_double, {}, "SomeController")
      end
    end
  end

  let(:warden_double) { double("warden") }
  let(:lead_id) { (10 * rand).round }
  let(:lead) { instance_double(Lead) }
  let(:mandate) { instance_double(Mandate) }

  it "includes the helpers" do
    expect(subject).to be_a(described_class)
  end

  describe "#current_lead" do
    before do
      allow(warden_double).to receive(:user).with(:lead)
      allow(warden_double).to receive(:user).with(:admin).and_return(nil)
    end

    it "should return nil, if no user there" do
      expect(subject.current_lead).to be_nil
    end

    context "when lead found" do
      before do
        allow(warden_double).to receive(:user).with(:lead).and_return("id" => lead_id)
        allow(warden_double).to receive(:user).with(:admin).and_return(nil)
        allow(Lead).to receive_message_chain(:active, :find_by).with(id: lead_id).and_return(lead)
        allow(lead).to receive(:inactive?).and_return(false)
      end

      it "it loads a lead, if it exists" do
        allow(lead).to receive(:mandate).and_return(mandate)
        expect(subject.current_lead).to eq(lead)
      end

      it "it loads a lead, if it exists and has no mandate" do
        allow(lead).to receive(:mandate).and_return(nil)
        allow(lead).to receive(:create_mandate).with(state: "not_started")
        expect(subject.current_lead).to eq(lead)
      end

      it "creates a mandate, if it is missing" do
        allow(lead).to receive(:mandate).and_return(nil)
        expect(lead).to receive(:create_mandate).with(state: "not_started")
        subject.current_lead
      end
    end

    context "lead exists but should be logged out" do
      before do
        allow(warden_double).to receive(:user).with(:lead).and_return("id" => lead_id)
        allow(warden_double).to receive(:user).with(:admin).and_return(nil)
        allow(Lead).to receive(:find_by).with(id: lead_id, state: "active").and_return(nil)
      end

      it "has to terminate the session for an inactive" do
        allow(lead).to receive(:inactive?).and_return(true)
        allow(lead).to receive(:active?).and_return(false)
        expect(warden_double).to receive(:logout).with(:lead)
        subject.current_lead
      end
    end
  end

  context "when signed as cookie exists" do
    let(:signed_as_mandate) { create(:mandate) }

    before do
      allow(subject).to receive(:signed_mandate_by_cookie).and_return(signed_as_mandate)
    end

    describe "current_lead" do
      it "returns the lead associated to the mandate in the signed as cookie value" do
        signed_as_lead = create(:lead, mandate: signed_as_mandate)
        expect(subject.current_lead).to eq(signed_as_lead)
      end
    end

    describe "current_mandate" do
      it "returns the mandate in the signed as cookie value " do
        expect(subject.current_mandate).to eq(signed_as_mandate)
      end
    end

    describe "current_user" do
      let!(:signed_as_user) { create(:user, mandate: signed_as_mandate) }
      let!(:admin_user) { create(:user) }

      before do
        allow(warden_double).to receive(:user).with(:user).and_return("id" => admin_user.id)
      end

      context "when in admin context" do
        before do
          allow(subject).to receive(:admin_context?).and_return(true)
        end

        it "will not return the user associated with to the mandate in the signed as cookie value" do
          expect(subject.current_user).not_to eq(signed_as_user)
        end
      end

      context "when not an admin context" do
        before do
          allow(subject).to receive(:admin_context?).and_return(false)
        end

        it "returns the user associated with to the mandate in the signed as cookie value" do
          expect(subject.current_user).to eq(signed_as_user)
        end
      end
    end
  end

  describe "#signed_mandate_by_cookie" do
    subject { AccountBaseHelperDummy.new(warden_double, cookies) }

    let(:cookies) { { Domain::Users::BackDoor::SIGNED_AS_COOKIE => sign_as_mandate.id } }
    let(:sign_as_mandate) { create(:mandate) }

    context "with admin session" do
      let(:admin) { create(:admin) }

      before do
        allow(warden_double).to receive(:user).with(:admin).and_return(admin)
      end

      it "returns the signed as mandate if there is an admin signed in session" do
        expect(subject.send(:signed_mandate_by_cookie)).to eq(sign_as_mandate)
      end
    end

    context "no admin in session" do
      before do
        allow(warden_double).to receive(:user).with(:admin).and_return(nil)
      end

      it "returns nil when there is no admin signed in the session" do
        expect(subject.send(:signed_mandate_by_cookie)).to be_nil
      end
    end
  end

  describe "#set_audit_person_for_business_events" do
    before do
      allow(warden_double).to receive(:user).with(:lead).and_return(nil)
      allow(warden_double).to receive(:user).with(:admin).and_return(nil)
      allow(warden_double).to receive(:user).with(:user).and_return(nil)
    end

    context "with admin logged in as customer" do
      subject { AccountBaseHelperDummy.new(warden_double, cookies) }

      let(:cookies) { { Domain::Users::BackDoor::SIGNED_AS_COOKIE => sign_as_mandate.id } }
      let(:admin) { create :admin }
      let(:sign_as_mandate) { create(:mandate) }

      before do
        allow(warden_double).to receive(:user).with(:admin).and_return(admin)
      end

      it "sets admin as audit person" do
        subject.set_audit_person_for_business_events
        expect(BusinessEvent.audit_person).to eq admin
      end
    end

    context "with lead customer" do
      let(:lead) { create :lead }

      before do
        allow(warden_double).to receive(:user).with(:lead).and_return(lead)
      end

      it "sets lead as audit person" do
        subject.set_audit_person_for_business_events
        expect(BusinessEvent.audit_person).to eq lead
      end
    end

    context "with user customer" do
      let(:user) { create :user }

      before do
        allow(warden_double).to receive(:user).with(:user).and_return(user)
      end

      it "sets user as audit person" do
        subject.set_audit_person_for_business_events
        expect(BusinessEvent.audit_person).to eq user
      end
    end

    context "with not authenticated customer" do
      it "doesn't set audit person" do
        subject.set_audit_person_for_business_events
        expect(BusinessEvent.audit_person).to eq nil
      end
    end
  end
end
