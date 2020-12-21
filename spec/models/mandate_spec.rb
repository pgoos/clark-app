# frozen_string_literal: true

# == Schema Information
#
# Table name: mandates
#
#  id                         :integer          not null, primary key
#  first_name                 :string
#  last_name                  :string
#  street                     :string
#  birthdate                  :datetime
#  gender                     :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  info                       :json
#  state                      :string
#  tos_accepted_at            :datetime
#  confirmed_at               :datetime
#  tracking_code              :string
#  newsletter                 :jsonb
#  company_name               :string
#  variety                    :string
#  encrypted_iban             :string
#  encrypted_iban_iv          :string
#  voucher_id                 :integer
#  qualitypool_id             :integer
#  contactable_at             :string
#  preferred_locale           :string
#  satisfaction               :jsonb            not null
#  loyalty                    :jsonb            not null
#  owner_ident                :string           default("clark"), not null
#  accessible_by              :jsonb            not null
#  health_and_care_insurance  :integer          default(0), not null
#  church_membership          :boolean          default(FALSE), not null
#  health_consent_accepted_at :datetime
#

require "rails_helper"

RSpec.describe Mandate, type: :model do
  let(:listener) { double("Domain::AcceptCustomers::AcceptedMandateNotifier") }

  before do
    allow(MandateMailer).to receive_message_chain("greeting.deliver_now")
  end

  it { is_expected.to be_valid }

  # Many methods would send out the greeting mail at the current config,
  # let's catch those cases until we move this out to an observer

  # Settings
  # Constants
  # Attribute Settings

  context "delegations" do
    it { is_expected.to delegate_method(:source_campaign).to(:user_or_lead) }
    it { is_expected.to delegate_method(:network).to(:user_or_lead) }
    it { is_expected.to delegate_method(:utm_content).to(:user_or_lead) }
    it { is_expected.to delegate_method(:utm_term).to(:user_or_lead) }
  end

  context "when user & lead is nil" do
    before do
      subject.user = nil
      subject.lead = nil
    end

    it "should return nil for user & led delegators" do
      expect(subject.network).to be_nil
      expect(subject.source_campaign).to be_nil
      expect(subject.partner_customer_id).to be_nil
    end

    it "should return 'Organic' for source" do
      expect(subject.source).to eq("Organic")
    end
  end

  context "with miles and more source" do
    let(:mandate) { create(:mandate, :mam) }

    it "identifies as mam enabled" do
      expect(mandate).to be_mam_enabled
    end

    it "returns nil as mam_member_alias" do
      expect(mandate.mam_member_alias).to be_nil
    end
  end

  context "with miles and more source and fetched status" do
    let(:mandate) { create(:mandate, :mam_with_status) }

    it "identifies as mam enabled" do
      expect(mandate).to be_mam_enabled
    end

    it "returns an mam_member_alias" do
      expect(mandate.mam_member_alias).to eq("992223020632830")
    end

    it "returns a member customer type" do
      expect(mandate.mam_customer_type).to eq(:base)
    end

    it "returns :sen in case of 'HON'" do
      mandate.loyalty["mam"]["status"] = "HON"
      expect(mandate.mam_customer_type).to eq(:sen)
    end

    it "returns :base in case of 'HON'" do
      mandate.loyalty["mam"]["status"] = "INST"
      expect(mandate.mam_customer_type).to eq(:base)
    end

    it "returns :base in case of ''" do
      mandate.loyalty["mam"]["status"] = ""
      expect(mandate.mam_customer_type).to eq(:base)
    end

    it "returns :ftl in case of 'FTL'" do
      mandate.loyalty["mam"]["status"] = "FTL"
      expect(mandate.mam_customer_type).to eq(:ftl)
    end

    it "returns :sen in case of 'SEN'" do
      mandate.loyalty["mam"]["status"] = "SEN"
      expect(mandate.mam_customer_type).to eq(:sen)
    end

    it "has 0 bookings" do
      expect(mandate.mam_booked_miles).to eq(0)
    end
  end

  context "without miles and more source" do
    let(:mandate) do
      create(:mandate, user: create(:user))
    end

    it "identifies as mam disabled" do
      expect(mandate).not_to be_mam_enabled
    end

    it "can get mam enabled" do
      mandate.enable_mam!
      mandate.reload
      expect(mandate).to be_mam_enabled
    end
  end

  describe "when accessing payback data" do
    context "when payback data is present" do
      let(:mandate) { build :mandate, :payback_with_data }

      it "identifies payback as present" do
        expect(mandate.payback_enabled?).to be true
      end

      it "returns payback number" do
        expect(mandate.payback_number).to eq mandate.loyalty["payback"]["paybackNumber"]
      end

      it "returns payback locked points" do
        expect(mandate.payback_locked_points).to eq mandate.loyalty["payback"]["rewardedPoints"]["locked"]
      end

      it "returns payback unlocked points" do
        expect(mandate.payback_unlocked_points).to eq mandate.loyalty["payback"]["rewardedPoints"]["unlocked"]
      end

      it "returns payback data hash" do
        expect(mandate.payback_data).to eq mandate.loyalty["payback"]
      end
    end

    context "when payback data is not present" do
      let(:mandate) { build :mandate }

      it "returns false when checking for payback data" do
        expect(mandate.payback_enabled?).to be false
      end

      it "returns nil for payback number" do
        expect(mandate.payback_number).to be_nil
      end

      it "returns nil for payback locked points" do
        expect(mandate.payback_locked_points).to be_nil
      end

      it "returns nil for payback unlocked points" do
        expect(mandate.payback_unlocked_points).to be_nil
      end

      it "returns nil for payback data hash" do
        expect(mandate.payback_data).to be_nil
      end
    end
  end

  context "with ing source" do
    let(:mandate) do
      create(:mandate, user: create(:user, source_data: {}))
    end

    it "identifies ing as enabled" do
      mandate.enable_ing!
      mandate.reload
      expect(mandate.partner).to eq("ing-diba")
    end

    it "identifies ing as disabled" do
      expect(mandate.partner).to be_nil
    end
  end

  context "with partner source source" do
    let(:mandate) do
      create(:mandate, user: create(:user, source_data: {}))
    end

    context "with an assona user" do
      it "identifies assona as enabled" do
        mandate.enable_partner "assona"
        mandate.reload
        expect(mandate.partner).to eq("assona")
      end

      it "identifies assona as disabled" do
        expect(mandate.partner).to be_nil
      end
    end

    context "with a finanzblick user" do
      it "identifies finanzblick as enabled" do
        mandate.enable_partner "finanzblick"
        mandate.reload
        expect(mandate.partner).to eq("finanzblick")
      end

      it "identifies finanzblick as disabled" do
        expect(mandate.partner).to be_nil
      end
    end

    context "with a Primoco user" do
      it "identifies Primoco as enabled" do
        mandate.enable_partner "primoco"
        mandate.reload
        expect(mandate.partner).to eq("primoco")
      end

      it "identifies Primoco as disabled" do
        expect(mandate.partner).to be_nil
      end
    end

    context "with a PSD user" do
      it "identifies PSD as enabled" do
        mandate.enable_partner "psd-bank"
        mandate.reload
        expect(mandate.partner).to eq("psd-bank")
      end

      it "identifies PSD as disabled" do
        expect(mandate.partner).to be_nil
      end
    end
  end

  context "with an encrypted IBAN" do
    it "stores iban encrypted" do
      expect { subject.iban = "DE12500105170648489890" }
        .to change(subject, :encrypted_iban)
        .and change(subject, :encrypted_iban_iv)
    end

    it "removes spaces from the IBAN" do
      subject.iban = "DE12 5001 0517 0648 4898 90"
      subject.validate

      expect(subject.send(:iban)).to eq("DE12500105170648489890")
    end
  end

  context "with satisfaction metrics" do
    let(:mandate) { create(:mandate) }

    it "stores nps_score" do
      mandate.nps_score = 10
      mandate.save

      mandate.reload
      expect(mandate.nps_score).to eq(10)
    end

    it "stores nps_refusal" do
      mandate.nps_refusal = true
      mandate.save

      mandate.reload
      expect(mandate.nps_refusal).to be(true)
    end

    it "stores nps_answered_at" do
      date = Time.zone.now
      mandate.nps_answered_at = date.to_s
      mandate.save

      mandate.reload
      expect(mandate.nps_answered_at).to eq(date.to_s)
    end
  end

  describe "#phone" do
    let(:mandate) { build(:mandate, phone: phone_number) }

    context "when number is valid" do
      let(:phone_number) { "+4912222222" }

      it "is valid" do
        expect(mandate).to be_valid
      end
    end

    context "when number is valid" do
      let(:phone_number) { "+491" }

      it "isn't valid" do
        expect(mandate).not_to be_valid
      end
    end
  end

  # Plugins
  # Concerns

  it_behaves_like "a commentable model"
  it_behaves_like "accessible"
  it_behaves_like "a documentable"

  context "when events are published to remote consumers" do
    context "when the address is updated", :integration do
      let(:mandate) do
        subject.active_address = build(:address)
        subject.save!
        subject
      end
      let(:sqs_client) { double("Aws::SQS::Client") }

      before do
        mandate.grant_access_for!("api_partner")
        allow(Features).to receive(:active?).and_return(true)
      end

      it_behaves_like "event_publishable"

      it "should not publish events to remote, as long as the new address is not the active address" do
        allow(Aws::SQS::Client).to receive(:new) { sqs_client }
        expect(sqs_client).not_to receive(:send_message)
        create(:address, :inactive, accepted: false, mandate: subject)
      end

      it "should publish events to remote, if the new address is being accepted" do
        address = create(:address, :inactive, accepted: false, mandate: subject)

        # The sequence to set the attributes accordingly is being taken from Domain::Addresses::Accept!
        address.accept!

        expect(Mandate).to receive(:publish_event).with(mandate, "updated", "update")
        address.activate!
      end
    end
  end

  it { is_expected.to be_a(PasswordGenerator) }

  context "with shared examples for user or lead" do
    context "user" do
      let(:shared_example_model) { create(:mandate, user: create(:user)) }

      it_behaves_like "an auditable model"
    end
  end

  # State Machine

  describe "state machine" do
    context "with initial state" do
      let(:mandate) { create(:mandate, tos_accepted_at: Time.zone.now) }

      it "is in_creation" do
        expect(mandate.state).to eq("in_creation")
      end

      it "transitions to created" do
        expect(mandate.complete).to eq(true)
        expect(mandate.state).to eq("created")
      end

      it "does not transition to other states" do
        expect(mandate.accept).to eq(false)
        expect(mandate.reject).to eq(false)
        expect(mandate.revoke).to eq(false)
        expect(mandate.reset).to eq(false)
      end
    end

    context "when approved" do
      let(:mandate) do
        create(:mandate, state: "created", inquiries: [create(:inquiry)])
      end

      before do
        create(:user, mandate: mandate)
      end

      it "accepts the inquiries" do
        expect { mandate.accept }
          .to change { mandate.inquiries.first.state }
          .from("in_creation").to("pending")
      end
    end

    context "when canceled" do
      let(:mandate) do
        create(:mandate, state: "created", inquiries: [create(:inquiry)])
      end

      it "cancels the inquiries" do
        expect { mandate.revoke }
          .to change { mandate.inquiries.first.state }
          .from("in_creation").to("canceled")
      end
    end

    context "with state: created" do
      let(:mandate) { create(:mandate, state: "created") }

      before do
        create(:user, mandate: mandate)
      end

      it "is created" do
        expect(mandate.state).to eq("created")
      end

      it "transitions to accepted" do
        expect(mandate.accept).to eq(true)
        expect(mandate.state).to eq("accepted")
      end

      it "transitions to rejected" do
        expect(mandate.reject).to eq(true)
        expect(mandate.state).to eq("rejected")
      end

      it "transitions to revoked" do
        expect(mandate.revoke).to eq(true)
        expect(mandate.state).to eq("revoked")
      end

      it "does not transition to other states" do
        expect(mandate.complete).to eq(false)
        expect(mandate.reset).to eq(false)
      end

      context "when targeting as wizard step is missing" do
        let(:mandate) do
          create(
            :mandate,
            :created,
            tos_accepted_at: DateTime.current,
            confirmed_at: DateTime.current,
            signature: create(:signature)
          )
        end

        before do
          FactoryBot.create(:user, mandate: mandate)
          mandate.info = { "wizard_steps" => %w[profiling confirming], "tracking_allowed" => true }
        end

        it "should validate to false, if the targeting step is missing" do
          expect(mandate).not_to be_valid
          expect(mandate.errors.messages).to have_key(:targeting?)
          expect(mandate.accept).to be_falsey
        end

        it "should be acceptable if the customer state is present" do
          mandate.customer_state = "self_service"
          expect(mandate).to be_valid
          expect(mandate.accept).to be_truthy
          expect(mandate).to be_accepted
          expect(mandate).to be_valid
        end
      end
    end

    context "with state: rejected" do
      let(:mandate) do
        create(:mandate, state: "rejected", inquiries: [create(:inquiry)], user: create(:user))
      end

      it "is rejected" do
        expect(mandate.state).to eq("rejected")
      end

      it "transitions to in_creation" do
        expect(mandate.reset).to eq(true)
        expect(mandate.state).to eq("in_creation")
      end

      it "transitions to revoked" do
        expect(mandate.revoke).to eq(true)
        expect(mandate.state).to eq("revoked")
      end

      it "does not transition to other states" do
        expect(mandate.complete).to eq(false)
        expect(mandate.accept).to eq(false)
        expect(mandate.reject).to eq(false)
      end
    end

    context "with state: accepted" do
      let(:mandate) { create(:mandate, state: "accepted") }

      it "is accepted" do
        expect(mandate.state).to eq("accepted")
      end

      it "transitions to revoked" do
        expect(mandate.revoke).to eq(true)
        expect(mandate.state).to eq("revoked")
      end

      it "does not transition to other states" do
        expect(mandate.complete).to eq(false)
        expect(mandate.accept).to eq(false)
        expect(mandate.reject).to eq(false)
        expect(mandate.reset).to eq(false)
      end
    end

    context "with state: revoked" do
      let(:mandate) { create(:mandate, state: "revoked") }

      it "is revoked" do
        expect(mandate.state).to eq("revoked")
      end

      it "does not transition to any other states" do
        expect(mandate.reset).to eq(false)
        expect(mandate.complete).to eq(false)
        expect(mandate.accept).to eq(false)
        expect(mandate.reject).to eq(false)
        expect(mandate.revoke).to eq(false)
      end
    end

    context "with state: freebie" do
      # Only use build here so that we don't run into all validations
      let(:mandate) { build(:mandate, state: "freebie") }

      it "is in freebie state" do
        expect(mandate).to be_freebie
      end

      it "can be completed" do
        expect(mandate.complete).to be_truthy
        expect(mandate).to be_created
      end

      it "does not transition to other states" do
        expect(mandate.accept).to be_falsey
        expect(mandate.reject).to be_falsey
        expect(mandate.revoke).to be_falsey
        expect(mandate.reset).to be_falsey
      end
    end

    context "with state: not_started" do
      # Only use build here so that we don't run into all validations
      let(:mandate) { build(:mandate, state: "not_started") }

      it "is in not_started state" do
        expect(mandate).to be_not_started
      end

      it "can be completed" do
        expect(mandate.complete).to be_truthy
        expect(mandate).to be_created
      end

      it "does not transition to other states" do
        expect(mandate.accept).to be_falsey
        expect(mandate.reject).to be_falsey
        expect(mandate.revoke).to be_falsey
        expect(mandate.reset).to be_falsey
      end
    end

    context "after_transition handlers" do
      it "does not call `send_greeting_mail` if the mandate is moved to created" do
        mandate = FactoryBot.build(
          :mandate, state: "in_creation", user: FactoryBot.build(:user)
        )

        expect(mandate).not_to receive(:send_greeting_mail)
        mandate.complete!
      end

      context "when mandates is moved to accepted" do
        context "with revoked state" do
          it "does not send any emails" do
            mandate = build :mandate, :revoked, :confirmed, :with_accepted_tos, user: build(:user)
            expect(mandate).not_to receive(:send_greeting_mail)
            expect(mandate).not_to receive(:send_adjust_accept_tracking)
            mandate.reactivate!
          end
        end

        context "with created state" do
          it "calls `send_greeting_mail`" do
            mandate = build :mandate, :created
            mandate.subscribe(listener)
            expect(listener).to receive(:send_greeting_mail).with(mandate)
            expect { mandate.accept! }.to broadcast(:send_greeting_mail, mandate)
          end

          it "calls `send_adjust_accept_tracking`" do
            mandate = build :mandate, :created
            mandate.subscribe(listener)
            expect(listener).to receive(:send_adjust_accept_tracking).with(mandate)
            expect { mandate.accept! }.to broadcast(:send_adjust_accept_tracking, mandate)
          end
        end

        context "when mandate is with payback network" do
          let(:listener) { double("Domain::Mandates::PaybackCustomerAccepted") }
          let(:mandate) { build :mandate, :created, :payback_with_data }

          it "calls `payback_customer_accepted`" do
            mandate.subscribe(listener)
            expect(listener).to receive(:payback_customer_accepted).with(mandate)
            expect { mandate.accept! }.to broadcast(:payback_customer_accepted, mandate)
          end
        end

        context "when mandate is not with payback network" do
          let(:listener) { double("Domain::Mandates::PaybackCustomerAccepted") }
          let(:mandate) { build :mandate, :created }

          it "doesn't call `payback_customer_accepted`" do
            mandate.subscribe(listener)
            expect(listener).not_to receive(:payback_customer_accepted).with(mandate)
            expect { mandate.accept! }.not_to broadcast(:payback_customer_accepted, mandate)
          end
        end
      end
    end

    describe "#reactivate" do
      subject do
        build :mandate, :revoked, :confirmed, :with_accepted_tos, user: build(:user)
      end

      it { expect(subject.reactivate).to eq true }

      context "when mandate is not revoked" do
        subject do
          build :mandate, :created, :confirmed, :with_accepted_tos, user: build(:user)
        end

        it { expect(subject.reactivate).to eq false }
      end

      context "without email" do
        subject do
          build :mandate, :revoked, :confirmed, :with_accepted_tos, user: build(:user, email: nil)
        end

        it { expect(subject.reactivate).to eq false }
      end

      context "with empty confirmed_at" do
        subject do
          build :mandate, :revoked, :with_accepted_tos, user: build(:user)
        end

        it { expect(subject.reactivate).to eq false }
      end

      context "with empty tos_accepted_at" do
        subject do
          build :mandate, :revoked, :confirmed, user: build(:user)
        end

        it { expect(subject.reactivate).to eq false }
      end
    end
  end

  describe "accept_gkv_inquiries" do
    let!(:gkv_category) { create(:category_gkv) }

    it "accepts the gkv inquiries after the user moves to created state" do
      mandate = create(:mandate, state: "in_creation", user: FactoryBot.build(:user))
      gkv_inquiry = create(:inquiry, mandate: mandate)
      create(:inquiry_category, category: gkv_category,
                                inquiry:  gkv_inquiry)

      mandate.complete
      expect(gkv_inquiry.reload.state).to eq(:pending.to_s)
    end

    it "accepts only gkv inquiries and does not change the other inquiries after the user moves to created state" do
      mandate = create(:mandate, state: "in_creation", user: FactoryBot.build(:user))
      non_gkv_inquiry = create(:inquiry)
      mandate.complete
      expect(non_gkv_inquiry.reload.state).to eq(:in_creation.to_s)
    end
  end

  describe "#not_created_yet?" do
    subject { mandate.not_created_yet? }

    not_started_yet_states = %w[freebie in_creation not_started]
    all_states             = Mandate.state_machine.states.map(&:name).map(&:to_s)

    not_started_yet_states.each do |state|
      context "when mandate state is #{state}" do
        let(:mandate) { build(:mandate, state: state) }

        it { is_expected.to be true }
      end
    end

    (all_states - not_started_yet_states).each do |state|
      context "when mandate state is #{state}" do
        let(:mandate) { build(:mandate, state: state) }

        it { is_expected.to be false }
      end
    end
  end

  # Scopes

  describe ".by_id" do
    subject { Mandate.by_id(id) }

    let(:id) { 1 }

    before do
      @mandate1 = create :mandate, id: 1
      @mandate2 = create :mandate, id: 2
    end

    it { is_expected.to include(@mandate1) }
    it { is_expected.not_to include(@mandate2) }

    context "when id has more than 4 bytes" do
      let(:id) { 2_147_483_648 }

      it "raises RangeError when creating a new record" do
        expect { create(:mandate, id: id) }.to raise_error(ActiveModel::RangeError)
      end

      it "suppress RangeError and return an empty relation when reading" do
        expect(Mandate.by_id(id)).to be_empty
      end
    end
  end

  describe ".by_reference_id" do
    subject { Mandate.by_reference_id(reference_id) }

    let(:reference_id) { 123_123_123 }

    before do
      @mandate1 = create :mandate, info: {reference_id: 123_123_123}
      @mandate2 = create :mandate, info: {reference_id: 456_456_456}
    end

    it { is_expected.to include(@mandate1) }
    it { is_expected.not_to include(@mandate2) }
  end

  it_behaves_like "a model providing a contains-scope on",
                  :first_name, :last_name

  describe ".by_id_first_name_cont_last_name_cont_email_cont" do
    subject { Mandate.by_id_first_name_cont_last_name_cont_email_cont(query_string) }

    let(:user1) { create(:user, email: "user@test1.com") }
    let(:user2) { create(:user, email: "jane_doe@test2.com") }
    let(:user3) { create(:user, email: "john_doe@test2.com") }
    let(:user4) { create(:user, email: "mark@test4.com") }

    let(:mandate1) do
      create(:mandate, id: 1, first_name: "Peter", last_name: "Shmidt", user: user1, company_name: "My Company")
    end
    let(:mandate2) { create(:mandate, id: 2, first_name: "Jane", last_name: "Doe", user: user2) }
    let(:mandate3) { create(:mandate, id: 3, first_name: "John", last_name: "Doe", user: user3) }
    let(:mandate4) { create(:mandate, id: 4, first_name: "Mark", last_name: "Doe", user: user4) }

    let!(:mandates) do
      mandate1
      mandate2
      mandate3
      mandate4
    end

    context "when searching by id" do
      let(:query_string) { "2" }

      it { is_expected.to match_array([mandate2]) }
    end

    context "when there are matching last name" do
      let(:query_string) { "doe" }

      it { is_expected.to match_array([mandate2, mandate3, mandate4]) }
    end

    context "when searching by email" do
      let(:query_string) { "jane_doe@test2.com" }

      it "invokes :by_email scope and returns a result" do
        expect(Mandate).to receive(:by_email).and_return([mandate2])
        expect(subject).to match_array([mandate2])
      end
    end

    context "when there is matching first name" do
      let(:query_string) { "pete" }

      it { is_expected.to match_array([mandate1]) }
    end

    context "when there is matching last name" do
      let(:query_string) { "shm" }

      it { is_expected.to match_array([mandate1]) }
    end

    context "when there is matching full name" do
      let(:query_string) { "er shm" }

      it { is_expected.to match_array([mandate1]) }
    end

    context "when there is matching company name" do
      let(:query_string) { "my comp" }

      it { is_expected.to match_array([mandate1]) }
    end
  end

  describe ".by_email" do
    subject { Mandate.by_email(query_string) }

    let(:email) { "ineedmorecheese@clark.de" }
    let!(:dummy_mandate) { create(:mandate, user: create(:user), lead: create(:lead)) }

    shared_examples "returns related mandate" do
      it { is_expected.to match_array([mandate]) }
    end

    context "when there is a lead with target email" do
      let(:query_string) { mandate.lead.email }
      let(:mandate) { create(:mandate, lead: create(:lead)) }

      it_behaves_like "returns related mandate"
    end

    context "when there is a user with target email" do
      let(:query_string) { mandate.user.email }
      let(:mandate) { create(:mandate, user: create(:user)) }

      it_behaves_like "returns related mandate"
    end

    context "when there is a lead and a user with target email" do
      let(:query_string) { email }
      let!(:mandate) { create(:mandate, lead: create(:lead, email: email), user: create(:user, email: email)) }

      it_behaves_like "returns related mandate"
    end

    context "when there aren't any leads or mandates with target email" do
      let(:query_string) { email }

      it "returns empty array" do
        expect(subject).to be_empty
      end
    end
  end

  context "search by 'id' and / or 'first_name' and / or 'last_name'" do
    before do
      @mandate1 = create(:mandate, id: 1, first_name: "Peter", last_name: "Mueller")
      @mandate2 = create(:mandate, id: 2, first_name: "Uli",   last_name: "Müller")
    end

    describe ".by_id_first_name_cont_last_name_cont" do
      subject { Mandate.by_id_first_name_cont_last_name_cont(query_string) }

      context "when searching by id" do
        let(:query_string) { "1" }

        it { is_expected.to include(@mandate1) }
        it { is_expected.not_to include(@mandate2) }
      end

      context "when searching by first name" do
        let(:query_string) { "Pet" }

        it { is_expected.to include(@mandate1) }
        it { is_expected.not_to include(@mandate2) }
      end

      context "when searching by last name" do
        let(:query_string) { "eller" }

        it { is_expected.to include(@mandate1) }
        it { is_expected.not_to include(@mandate2) }
      end
    end

    describe ".by_last_name_cont" do
      subject { Mandate.by_last_name_cont(query_string) }

      context "when searching with umlaut" do
        let(:query_string) { "Müll " }

        it { is_expected.to include(@mandate1) }
        it { is_expected.to include(@mandate2) }
      end

      context "when search shoul predict umlaut" do
        let(:query_string) { "Muell" }

        it { is_expected.to include(@mandate1) }
        it { is_expected.to include(@mandate2) }
      end
    end
  end

  describe "when filtered by_zipcode_cont", :integration do
    it "not raise an error, if the zip code is given" do
      query_string = "12123"
      matching_with_zipcode = create(
        :mandate,
        user: create(:user),
        addresses: [
          create(:address, zipcode: query_string)
        ]
      )
      create(
        :mandate,
        user: create(:user),
        addresses: [
          create(:address, zipcode: "54321")
        ]
      )
      create(:mandate)
      expect(Mandate.by_zipcode_cont(query_string)).to contain_exactly(matching_with_zipcode)
    end
  end

  describe ".by_birthdate" do
    subject { Mandate.by_birthdate(random_birthdate).count }

    let(:random_birthdate) { "15.12.1989" }

    before do
      create_list(:mandate, 2, birthdate: random_birthdate)
      create(:mandate, birthdate: nil)
      create(:mandate, birthdate: "01/01/1960")
      create(:mandate, birthdate: "11/11/1976")
    end

    it { is_expected.to eq(2) }
  end

  describe ".by_phone_number" do
    subject { Mandate.by_phone_number(query_string) }

    let(:phone_number)     { "+499876543210" }
    let(:different_number) { "+499876543211" }
    let(:query_string)     { phone_number }

    it "is empty if numbers don't match" do
      create(:mandate, phone: different_number)
      expect(subject.empty?).to be(true)
    end

    it "finds the entity if matching" do
      mandate = create(:mandate, phone: phone_number)
      expect(subject).to include(mandate)
    end

    it "finds all matching entities" do
      mandate1 = create(:mandate, phone: phone_number)
      mandate2 = create(:mandate, phone: phone_number)
      expect(subject).to include(mandate1, mandate2)
    end
  end

  describe ".by_welcome_call_status" do
    let(:mandate_successful_welcome_call)   { create(:mandate) }
    let(:mandate_unsuccessful_welcome_call) { create(:mandate) }
    let!(:mandate_no_welcome_call)          { create(:mandate) }

    before do
      create(:welcome_call, :successful, mandate: mandate_successful_welcome_call)
      create(:welcome_call, :unsuccessful, mandate: mandate_unsuccessful_welcome_call)
    end

    it "returns only mandate with succesful welcome calls when called with successful status" do
      expect(Mandate.by_welcome_call_status(Interaction::PhoneCall.call_states[:successful].to_s))
        .to eq([mandate_successful_welcome_call])
    end

    it "returns only mandate with unsuccesful welcome calls when called with unsuccessful status" do
      expect(Mandate.by_welcome_call_status(Interaction::PhoneCall.call_states[:unsuccessful].to_s))
        .to eq([mandate_unsuccessful_welcome_call])
    end

    it "returns only mandate with no welcome calls when called with not attempted status" do
      expect(Mandate.by_welcome_call_status(Interaction::PhoneCall.call_states[:not_attempted].to_s))
        .to eq([mandate_no_welcome_call])
    end
  end

  describe ".by_high_margin_status" do
    let(:ident) { Category::HIGH_MARGIN_CATEGORIES.sample }
    let(:mandate_with_high_margin) { create(:mandate) }
    let(:high_margin_category)     { create(:category, ident: ident) }
    let!(:mandate_no_high_margin)  { create(:mandate) }

    before do
      create(
        :opportunity,
        mandate:  mandate_with_high_margin,
        category: high_margin_category
      )
    end

    it "returns only mandate with high margin opportunities when called with yes state" do
      expect(Mandate.by_high_margin_status("Y")).to eq([mandate_with_high_margin])
    end

    it "returns only mandate with no high margin opportunities when called with no status" do
      expect(Mandate.by_high_margin_status("N")).to eq([mandate_no_high_margin])
    end
  end

  describe ".by_source" do
    let!(:mam_user)    { create(:user, :with_mandate, :mam_enabled) }
    let!(:mam_lead)    { create(:lead, :with_mandate, :mam_enabled) }
    let!(:normal_user) { create(:user, :with_mandate) }

    it "returns only mandate with the source in their associated user or lead source data" do
      expect(Mandate.by_source("mam")).to match_array([mam_user.mandate, mam_lead.mandate])
      expect(Mandate.by_source("mam")).not_to match_array([normal_user])
    end

    it "returns empty if no mandates with the source data" do
      expect(Mandate.by_source("not-found-source")).to eq([])
    end
  end

  describe ".portfolio_incomplete_between" do
    let(:valid_mandate) { create(:mandate) }
    let(:invalid_mandate) { create(:mandate) }

    before do
      whitelisted_company = create(:company, inquiry_blacklisted: false)
      blacklisted_company = create(:company, inquiry_blacklisted: true)
      create(:inquiry, mandate:    valid_mandate,
                       state:      "contacted",
                       company:    whitelisted_company,
                       updated_at: 2.days.ago)
      create(:inquiry, mandate:    invalid_mandate,
                       state:      "contacted",
                       company:    blacklisted_company,
                       updated_at: 2.days.ago)
    end

    it "should not include the mandate with an inquiry of a blacklisted company" do
      result = Mandate.portfolio_incomplete_between(1.day.ago)
      expect(result).to include(valid_mandate)
      expect(result).not_to include(invalid_mandate)
    end
  end

  context ".mandates_with_2_or_more_elligable_paid_out_products" do
    let(:user_1) { create :user, :with_mandate, :direkt_1822 }
    let(:user_2) { create :user, :with_mandate, :direkt_1822 }
    let!(:product1) { create(:product, :details_available, mandate: user_1.mandate) }
    let!(:product2) { create(:product, :details_available, mandate: user_1.mandate) }
    let!(:product3) { create(:product, :details_available, mandate: user_2.mandate) }

    it "returns the correct mandate with 2 or more valid products if no excluded category" do
      user_1.mandate.update!(state: :accepted)
      user_2.mandate.update!(state: :accepted)
      result = Mandate.mandates_with_2_or_more_elligable_paid_out_products("1822direkt")
      expect(result[0]).to eq(user_1.mandate)
      expect(result[1]).to be_nil
    end

    context "with excluded categories idents" do
      before do
        allow(Domain::MasterData::Categories).to receive(:get_by_ident).and_return(product1.plan.category,
                                                                                   product2.plan.category, product3.plan.category)
      end

      it "filters the mandate with a product of category excluded" do
        user_1.mandate.update!(state: :accepted)
        user_2.mandate.update!(state: :accepted)
        result = Mandate.mandates_with_2_or_more_elligable_paid_out_products("1822direkt",
                                                                             [product1.plan.category_ident])
        expect(result[0]).to be_nil
      end
    end

    context "with mandate not accepted" do
      before do
        allow(Domain::MasterData::Categories).to receive(:get_by_ident).and_return(product1.plan.category,
                                                                                   product2.plan.category, product3.plan.category)
      end

      it "filters the mandates which are not accepted" do
        result = Mandate.mandates_with_2_or_more_elligable_paid_out_products("1822direkt", [product1.plan.category_ident])
        expect(result[0]).to be_nil
      end
    end
  end

  describe ".by_mam_account_number" do
    let(:mam_account_number) { "123456789" }
    let!(:mam_mandate) { create(:mandate, :mam_with_status, mmAccountNumber: mam_account_number) }

    it "returns only mandate with the mam account number" do
      expect(Mandate.by_mam_account_number(mam_account_number)).to match_array([mam_mandate])
    end

    it "returns empty if no mandates with the source data" do
      expect(Mandate.by_mam_account_number("1111111")).to eq([])
    end
  end

  describe ".invitee" do
    let!(:user_1) { create :user, :with_mandate }
    let!(:user_2) { create :user, :with_mandate }

    it "returns nothing since no inviter relation is present" do
      expect(Mandate.invitee.count).to eq(0)
    end

    it "returns a mandate of user 2 when linked with user 1 as its inviter" do
      user_2.inviter_id = user_1.id
      user_2.save!
      expect(Mandate.invitee.count).to eq(1)
    end
  end

  # Associations

  it { expect(subject).to have_one(:user).dependent(:destroy) }
  it { expect(subject).to have_one(:lead).dependent(:destroy) }
  it { expect(subject).to have_many(:signatures).dependent(:destroy) }
  it { expect(subject).to have_many(:documents).dependent(:destroy) }
  it { expect(subject).to have_many(:products).dependent(:restrict_with_error) }
  it { expect(subject).to have_many(:inquiries) }
  it { expect(subject).to have_many(:companies).through(:inquiries) }
  it { expect(subject).to have_many(:questionnaire_responses) }
  it { expect(subject).to have_many(:recommendations).dependent(:destroy) }
  it { expect(subject).to have_many(:profile_data).dependent(:destroy) }
  it { expect(subject).to have_many(:follow_ups).dependent(:destroy) }
  it { expect(subject).to have_many(:interactions).dependent(:destroy) }
  it { expect(subject).to have_many(:opportunities).dependent(:restrict_with_error) }
  it { expect(subject).to have_many(:feed_logs).dependent(:destroy) }
  it { expect(subject).to have_many(:appointments).dependent(:destroy) }
  it { expect(subject).to belong_to(:voucher) }
  it { expect(subject).to have_one(:retirement_cockpit) }

  # Nested Attributes

  it { expect(subject).to accept_nested_attributes_for(:recommendations) }

  # Validations

  describe "validations for profiling wizard step" do
    before do
      subject.current_wizard_step = :profiling
    end

    %i[gender first_name last_name birthdate].each do |attr|
      it { expect(subject).to validate_presence_of(attr) }
    end

    it do
      expect(subject).to validate_inclusion_of(:gender)
        .in_array(Settings.attribute_domains.gender.map(&:to_s))
    end

    it "validates primary address and adds errors to mandate" do
      subject.active_address.city = ""
      subject.validate
      expect(subject.errors[:city]).not_to be_blank
    end

    it "validates birthdate" do
      mandate = create(:mandate, user: create(:user))
      mandate.current_wizard_step = :profiling
      expect(mandate.valid?).to eq true

      mandate.birthdate = 131.years.ago
      expect(mandate.valid?).to eq false

      mandate.birthdate = 16.years.ago
      expect(mandate.valid?).to eq false

      mandate.gender = "company"
      expect(mandate.company_account?).to eq true
      mandate.birthdate = 16.years.ago
      expect(mandate.valid?).to eq true
    end
  end

  describe "validation for confirming wizard step" do
    before { allow(subject).to receive(:current_wizard_step).and_return(:confirming) }

    context "when all validations are required" do
      %i[gender first_name last_name birthdate].each do |attr|
        it { expect(subject).to validate_presence_of(attr) }
      end

      it do
        expect(subject).to validate_inclusion_of(:gender)
          .in_array(Settings.attribute_domains.gender.map(&:to_s))
      end
    end

    describe "#skip_tos_validation" do
      before do
        allow(Settings).to(
          receive_message_chain("tos.validation.required").and_return(tos_required)
        )

        subject.tos_accepted = tos_accepted
        subject.skip_tos_validation = skip_tos_validation
        subject.validate
      end

      let(:skip_tos_validation) { false }

      context "when skip_tos_validation enabled" do
        let(:tos_required) { true }

        context "when tos is accepted" do
          let(:tos_accepted) { true }

          it "has no tos_accepted error" do
            expect(subject.errors[:tos_accepted]).to be_empty
          end
        end

        context "when tos isn't accepted" do
          let(:tos_accepted) { false }

          context "when tos validation isn't forced to skip" do
            it "has tos_accepted error" do
              expect(subject.errors[:tos_accepted]).not_to be_empty
            end
          end

          context "when tos validation is forced to skip" do
            let(:skip_tos_validation) { true }

            it "has no tos_accepted error" do
              expect(subject.errors[:tos_accepted]).to be_empty
            end
          end
        end
      end

      context "when skip_tos_validation disabled" do
        let(:tos_required) { false }

        context "when tos isn't accepted" do
          let(:tos_accepted) { false }

          it "has no tos_accepted error" do
            expect(subject.errors[:tos_accepted]).to be_empty
          end
        end
      end
    end

    context "when skip_signature_validation" do
      before do
        allow(subject).to receive(:skip_signature_validation).and_return(true)
      end

      it "skips validation of signatures count" do
        subject.validate
        expect(subject.errors[:signature_count]).to be_empty
      end

      it "validates primary address and adds errors to mandate" do
        subject.active_address.city = ""
        subject.validate
        expect(subject.errors[:city]).not_to be_blank
      end
    end
  end

  describe "validations for the freebie state" do
    before { subject.state = "freebie" }

    %i[gender first_name last_name].each do |attr|
      it { expect(subject).to validate_presence_of(attr) }
    end

    it do
      expect(subject).to validate_inclusion_of(:gender)
        .in_array(Settings.attribute_domains.gender.map(&:to_s))
    end

    it "validates primary address and adds errors to mandate" do
      subject.active_address.city = ""
      subject.validate
      expect(subject.errors[:city]).not_to be_blank
    end
  end

  describe "validations for the not_started state" do
    before { subject.state = "not_started" }

    %i[gender first_name last_name phone].each do |attr|
      it { expect(subject).not_to validate_presence_of(attr) }
    end
  end

  context "IBAN" do
    before do
      allow(Settings).to(
        receive_message_chain("iban.allowed_countries")
          .and_return(allowed_countries)
      )
    end

    let(:allowed_countries) { { DE: true } }

    context "when country is allowed" do
      context "when IBAN is correct" do
        it "validates that the IBAN is valid" do
          subject.iban = "DE89 3704 0044 0532 0130 00"
          expect(subject).to be_valid
        end
      end

      context "when IBAN is incorrect" do
        it "validates that the IBAN is invalid" do
          subject.iban = "DE89 3704 xxxx xxxx 0130 00"
          expect(subject).not_to be_valid
        end
      end
    end

    context "when country isn't allowed" do
      let(:allowed_countries) { { FR: true } }

      it "validates that the IBAN is invalid" do
        subject.iban = "DE89 3704 0044 0532 0130 00"
        expect(subject).not_to be_valid
      end
    end

    it "allows the iban to be set to an empty value" do
      subject.iban = ""
      expect(subject).to be_valid
    end
  end

  context "contactable_at" do
    it "allows a valid values" do
      valid_values = ["00:22 - 33:33", "9:99 - 99:99", "2:00 - 3:00", "1:22 - 22:19"]
      expect(subject).to allow_value(*valid_values).for(:contactable_at)
    end

    it "does not allow invalid values" do
      invalid_values = ["foo", "22 - 23:00", "1:22 - 22:1", "1:11-12:12"]
      expect(subject).not_to allow_value(*invalid_values).for(:contactable_at)
    end
  end

  # Callbacks

  it_behaves_like "a model with callbacks", :before, :validation,
                  :create_mandate_document

  it_behaves_like "a model with callbacks", :before, :validation,
                  :remove_spaces_from_iban

  it_behaves_like "a model with callbacks", :before, :validation,
                  :set_tracking_code

  it_behaves_like "a model with callbacks", :before, :validation,
                  :trim_name_fields

  it_behaves_like "a model with callbacks", :before, :validation,
                  :titleize_name_fields

  it_behaves_like "a model with callbacks", :before, :validation,
                  :redeem_voucher

  context "callbacks" do
    let(:mandate) { create(:mandate) }

    it { expect(mandate).to callback(:publish_created_event).after(:create) }
    it { expect(mandate).to callback(:publish_updated_event_for_data_fields).after(:update) }
    it { expect(mandate).to callback(:publish_deleted_event).after(:destroy) }
  end

  describe "A mandate" do
    let!(:mandate) { create(:mandate) }

    context "with inquiries" do
      it "is not destroyed" do
        create(:inquiry, company: create(:company), mandate: mandate)
        expect(mandate.destroy).to eq(false)
        expect(mandate.errors[:base].first)
          .to eq(I18n.t("activerecord.errors.models.mandate.check_for_inquiries"))
      end
    end

    context "with no inquiries" do
      it "is destroyed" do
        expect { mandate.destroy }.to change(Mandate, :count).by(-1)
      end
    end
  end

  context "trims certain attributes" do
    it "trims first- and last-name" do
      subject.first_name = "Theo "
      subject.last_name  = " Tester    "
      subject.valid?

      expect(subject.first_name).to eq("Theo")
      expect(subject.last_name).to eq("Tester")
    end

    it "does not try to trim nil values" do
      subject.first_name = nil

      expect { subject.valid? }.not_to raise_error
      expect(subject.first_name).to eq(nil)
    end
  end

  context "titleize names" do
    it "titleize first- and last-name" do
      subject.first_name = "theo"
      subject.last_name  = "a.tester"
      subject.valid?

      expect(subject.first_name).to eq("Theo")
      expect(subject.last_name).to eq("A.Tester")
    end

    it "does not try to capitalize nil values" do
      subject.first_name = nil

      expect { subject.valid? }.not_to raise_error
      expect(subject.first_name).to eq(nil)
    end
  end

  # Instance Methods -------------------------------------------------------------------------------

  context "#full_info" do
    it "should not break, if there's no birthday" do
      expect(subject.birthdate).to be_nil
      expect {
        subject.full_info
      }.not_to raise_exception
    end
  end

  context "#pre_acceptance_state?" do
    described_class::PRE_ACCEPTANCE_STATES.each do |state|
      it "should be true for the pre acceptance state #{state}" do
        subject.state = state
        expect(subject.pre_acceptance_state?).to eq(true)

        subject.state = state.to_s
        expect(subject.pre_acceptance_state?).to eq(true)
      end
    end

    (Mandate.state_machine.states.keys - described_class::PRE_ACCEPTANCE_STATES).each do |state|
      it "should be false for the state #{state}" do
        subject.state = state
        expect(subject.pre_acceptance_state?).to eq(false)

        subject.state = state.to_s
        expect(subject.pre_acceptance_state?).to eq(false)
      end
    end
  end

  context ".mutate_login_credentials" do
    it "changes the user email and password" do
      mandate      = create(:mandate, user: create(:user))
      old_password = mandate.user.encrypted_password
      old_email    = mandate.user.email

      mandate.mutate_login_credentials!
      mandate.user.reload

      expect(mandate.user.encrypted_password).not_to eq(old_password)
      expect(mandate.user.email).not_to eq(old_email)
    end

    it "changes the user email and password even if customer revoked more than once" do
      now = Time.zone.now
      Timecop.freeze(now)

      user    = create(:user)
      mandate = create(:mandate, user: user)
      email   = mandate.user.email
      mandate.mutate_login_credentials!

      Timecop.travel(now.advance(seconds: 1))
      user_with_same_email             = create(:user, email: email)
      mandate_with_same_email          = create(:mandate, user: user_with_same_email)
      mandate_with_same_email_password = mandate_with_same_email.user.encrypted_password
      mandate_with_same_email_email    = mandate_with_same_email.user.email
      mandate_with_same_email.mutate_login_credentials!
      mandate_with_same_email.user.reload

      expect(mandate_with_same_email.user.encrypted_password)
        .not_to eq(mandate_with_same_email_password)

      expect(mandate_with_same_email.user.email).not_to eq(mandate_with_same_email_email)
      Timecop.return
    end
  end

  context ".original_email" do
    it "returns original email for revoked email based on timestamp" do
      mandate        = create(:mandate, user: create(:user))
      original_email = mandate.user.email
      mandate.complete!
      mandate.revoke!

      expect(mandate.original_email).to eq(original_email)
      expect(mandate.original_email).not_to eq(mandate.email)
    end

    it "returns the same email if mandate is not revoked or email wasn't mutated" do
      mandate = FactoryBot.build(:mandate, user: create(:user))
      expect(mandate.original_email).to eq(mandate.email)
    end
  end

  context "wizard methods", :business_events do
    let!(:be_user) { create(:user) }

    before { BusinessEvent.audit_person = be_user }

    it "creates business event when going to targeting" do
      mandate = create(:mandate)
      expect { mandate.targeting }
        .to change { mandate.business_events.where(action: "targeting").count }
        .by(1)
    end

    it "creates business event when going to profiling" do
      mandate = create(:wizard_targeted_mandate)
      expect { mandate.profiling }
        .to change { mandate.business_events.where(action: "profiling").count }
        .by(1)
    end

    it "creates business event when going to comfirming" do
      mandate = create(
        :signed_unconfirmed_mandate,
        tos_accepted_at: DateTime.current, confirmed_at: DateTime.current
      )
      expect { mandate.confirming }
        .to change { mandate.business_events.where(action: "confirming").count }
        .by(1)
    end
  end

  context "Mailing Methods" do
    let!(:mandate) { create(:mandate) }

    context "with users" do
      it "allows mailing when confirmed and subscribed" do
        create(:user, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate)
        expect(mandate).to be_mailing_allowed
      end

      it "forbids mailing if the mandate is revoked" do
        create(:user, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate)
        mandate.update(state: "revoked")
        expect(mandate).not_to be_mailing_allowed
      end

      it "forbids mailing when confirmed and unsubscribed" do
        create(
          :user,
          confirmed_at: 1.day.ago, subscriber: false, mandate: mandate
        )
        expect(mandate).not_to be_mailing_allowed
      end

      it "forbids mailing if user is deactivated" do
        create(
          :user, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate, state: "inactive"
        )
        expect(mandate).not_to be_mailing_allowed
      end

      it "forbids mailing if lead is deactivated" do
        create(
          :lead, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate, state: "inactive"
        )
        expect(mandate).not_to be_mailing_allowed
      end

      it "allows mailing of a specific newsletter when it is listed" do
        create(:user, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate)
        mandate.newsletter << "test-newsletter"
        expect(mandate).to be_mailing_allowed("test-newsletter")
      end

      it "forbids mailing of a specific newsletter when it is not listed" do
        create(:user, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate)
        expect(mandate).not_to be_mailing_allowed("test-newsletter")
      end
    end

    context "with leads" do
      it "allows mailing when confirmed and subscribed" do
        create(:lead, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate)
        expect(mandate).to be_mailing_allowed
      end

      it "forbids mailing when confirmed and unsubscribed" do
        create(:lead, confirmed_at: 1.day.ago, subscriber: false, mandate: mandate)
        expect(mandate).not_to be_mailing_allowed
      end

      it "allows mailing of a specific newsletter when it is listed" do
        create(:lead, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate)
        mandate.newsletter << "test-newsletter"
        expect(mandate).to be_mailing_allowed("test-newsletter")
      end

      it "forbids mailing of a specific newsletter when it is not listed" do
        create(:lead, confirmed_at: 1.day.ago, subscriber: true, mandate: mandate)
        expect(mandate).not_to be_mailing_allowed("test-newsletter")
      end
    end
  end

  describe "#filename" do
    context "when mandate has first name and last name" do
      let(:mandate) { create(:mandate) }

      it do
        expect(mandate.mandate_filename)
          .to eq [Mandate.model_name.human.downcase, mandate.first_name.downcase, mandate.last_name.downcase]
          .join("-")
      end
    end

    context "when mandate has no first name and last name" do
      subject { create(:mandate, first_name: nil, last_name: nil).mandate_filename }

      it      { is_expected.to eq Mandate.model_name.human.downcase }
    end
  end

  describe "#done_with_demandcheck?" do
    let(:mandate)      { create(:mandate) }
    let(:bedarfscheck) { create(:custom_questionnaire, identifier: "bedarfscheck") }
    let(:other_questionnaire) { create(:custom_questionnaire, identifier: "OTHER") }

    it "returns false if no questionnaire_response exists for the bedarfscheck" do
      expect(mandate).not_to be_done_with_demandcheck
    end

    it "returns false if the questionnaire_response is not completed" do
      create(:questionnaire_response, mandate: mandate, questionnaire: bedarfscheck)
      expect(mandate).not_to be_done_with_demandcheck
    end

    it "returns true if the questionnaire_response is completed" do
      create(:questionnaire_response, mandate: mandate,
                                      questionnaire: bedarfscheck, state: "completed")
      expect(mandate).to be_done_with_demandcheck
    end

    it "returns true if the questionnaire_response is analyzed" do
      create(:questionnaire_response, mandate: mandate,
                                      questionnaire: bedarfscheck, state: "analyzed")
      expect(mandate).to be_done_with_demandcheck
    end

    it "returns false if completed questionnaire_response is not from a bedarfscheck" do
      create(:questionnaire_response, mandate: mandate,
                                      questionnaire: other_questionnaire, state: "completed")
      expect(mandate).not_to be_done_with_demandcheck
    end
  end

  describe "#create_mandate_document" do
    let(:mandate_doc) { subject.send(:create_mandate_document) }

    context "when all wizard_steps performed" do
      before { allow(subject).to receive(:all_wizard_steps_performed?).and_return(true) }

      context "when no documents are present" do
        it { expect { mandate_doc }.to change { subject.documents.length }.by(1) }
      end

      context "when already having a mandate document" do
        let(:mandate) do
          create(
            :mandate,
            documents: [create(:document, document_type: DocumentType.mandate_document)]
          )
        end

        it { expect { mandate_doc }.not_to(change { mandate.documents.length }) }
      end

      context "when having other documents" do
        subject do
          create(
            :mandate,
            documents: [create(:document, document_type: DocumentType.reminder)]
          )
        end

        it { expect { mandate_doc }.to change { subject.documents.length }.by(1) }
      end
    end

    context "when not all wizard_steps performed" do
      before { allow(subject).to receive(:all_wizard_steps_performed?).and_return(false) }

      it { expect { mandate_doc }.not_to(change { subject.documents.length }) }
    end

    context "when skip_mandate_document_generation is set to true" do
      before { allow(subject).to receive(:skip_mandate_document_generation).and_return(true) }

      it { expect { mandate_doc }.not_to(change { subject.documents.length }) }
    end
  end

  context "accepting customers -> sending inquiries: states" do
    let(:mandate)             { create(:mandate, state: "created") }
    let(:company)             { create(:company, inquiry_blacklisted: false) }
    let(:blacklisted_company) { create(:company, inquiry_blacklisted: true) }
    let(:gkv_company)         { create(:gkv_company, inquiry_blacklisted: false) }

    before { create(:category_gkv) }

    context "#sendable_inquiries" do
      it "should include sendable inquiries" do
        inq1 = create(:inquiry, :accepted, mandate: mandate, company: company)
        inq2 = create(:inquiry, state: "in_creation", mandate: mandate, company: company)
        expect(mandate.sendable_inquiries).to include(inq1, inq2)
      end

      it "should exclude inquiries of different states than 'pending' and 'in_creation'" do
        Inquiry.state_machine.states.map(&:name).except(:in_creation, :pending).each do |state|
          create(:inquiry, mandate: mandate, company: company, state: state)
        end
        expect(mandate.sendable_inquiries).to be_empty
      end

      it "should exclude inquiries of blacklisted insurers" do
        inquiry = create(:inquiry, mandate: mandate, company: blacklisted_company)
        expect(mandate.sendable_inquiries).not_to include(inquiry)
      end

      it "should exclude GKV inquiries" do
        inquiry = create(:inquiry, mandate: mandate, company: gkv_company)
        expect(mandate.sendable_inquiries).not_to include(inquiry)
      end
    end

    it "selects #inquiries_awaiting_answer" do
      Inquiry.state_machine.states.map(&:name).except(:contacted).each do |state|
        create(:inquiry, mandate: mandate, company: company, state: state)
      end
      inq1 = create(:inquiry, mandate: mandate, company: company, state: "contacted")
      inq2 = create(:inquiry, mandate: mandate, company: company, state: "contacted")
      expect(mandate.inquiries_awaiting_answer).to match_array([inq1, inq2])
    end
  end

  context "#iban_for_display" do
    before do
      subject.iban = "DE12500105170648489890"
    end

    it "returns the IBAN in a cloaked way" do
      expect(subject.iban_for_display).to eq("DE12 **** **** **** **** 90")
    end

    it "returns the IBAN in a prettified way (when allowed)" do
      expect(subject.iban_for_display(true)).to eq("DE12 5001 0517 0648 4898 90")
    end

    context "when CipherError is thrown" do
      before do
        allow(Ibandit::IBAN).to receive(:new).and_raise(OpenSSL::Cipher::CipherError)
      end

      context "when env is production" do
        before { allow(Rails.env).to receive(:production?).and_return(true) }

        it "re-raise error" do
          expect { subject.iban_for_display }.to raise_error(OpenSSL::Cipher::CipherError)
        end
      end

      context "when env is not production" do
        it "returns error message" do
          expect(subject.iban_for_display).to eq("IBAN could not be decrypted")
        end
      end
    end
  end

  context "#open_inquiries" do
    let(:category) { create(:category) }

    context "without inquiry" do
      it "returns nil" do
        expect(subject.open_inquiries(category)).to eq []
      end
    end

    context "with a single inquiry category" do
      let(:inquiry_category) { create(:inquiry_category, category: category) }
      let(:inquiry) { create(:inquiry, inquiry_categories: [inquiry_category]) }

      it "returns the correct inquiry" do
        subject.inquiries = [inquiry]

        expect(subject.open_inquiries(category)). to eq [inquiry]
      end
    end

    context "with a combo category" do
      let(:combo_category) { create(:combo_category, included_categories: [category]) }
      let(:empty_combo_category) { create(:combo_category, included_categories: [create(:category)]) }

      let(:inquiry_category1) { create(:inquiry_category, category: category) }
      let(:inquiry1) { create(:inquiry, inquiry_categories: [inquiry_category1]) }

      let(:inquiry_category2) { create(:inquiry_category, category: combo_category) }
      let(:inquiry2) { create(:inquiry, inquiry_categories: [inquiry_category2]) }

      let(:inquiry_category3) { create(:inquiry_category, category: empty_combo_category) }
      let(:inquiry3) { create(:inquiry, inquiry_categories: [inquiry_category3]) }

      it "returns the correct inquiries" do
        subject.inquiries = [inquiry1, inquiry2, inquiry3]

        expect(subject.open_inquiries(category)). to eq [inquiry1, inquiry2]
      end
    end
  end

  context "#iban?" do
    it "returns true when an IBAN is set" do
      subject.iban = "DE12500105170648489890"
      expect(subject).to be_iban
    end

    it "returns false when an IBAN is not set" do
      subject.iban = nil
      expect(subject).not_to be_iban
    end
  end

  context "#send_greeting_mail", :integration do
    it "does not send out the greeting email to a device lead" do
      mandate = create(
        :mandate, state: "in_creation", lead: create(:device_lead)
      )

      expect(MandateMailer).not_to receive(:greeting)
      expect { mandate.send(:send_greeting_mail_event) }.to broadcast(:send_greeting_mail)
    end

    it "does not send out the greeting mail when it was sent before" do
      mandate = create(:mandate, state: "created", user: create(:user))
      mandate.documents << create(
        :document, document_type: DocumentType.greeting
      )
      mandate.subscribe(listener)
      expect(MandateMailer).not_to receive(:greeting)
      expect { mandate.accept! }.to broadcast(:send_greeting_mail)
    end

    it "sends out the greeting mail if it was not sent before" do
      mandate = create(:mandate, state: "created", user: create(:user))
      mandate.subscribe(listener)
      expect(listener).to receive(:send_greeting_mail).with(mandate)
      expect { mandate.accept! }.to broadcast(:send_greeting_mail)
    end
  end

  context "#redeem_voucher" do
    let!(:voucher) { create(:voucher) }
    let!(:mandate) { create(:mandate) }
    let!(:user)    { create(:user, mandate: mandate) }

    it "does not try to redeem a voucher when no voucher_code is set" do
      expect(Voucher).not_to receive(:redeem_for).with(mandate)
      mandate.voucher_code = nil
      mandate.send(:redeem_voucher)
    end

    it "does not try to redeem a voucher when voucher_code is set to an empty string" do
      expect(Voucher).not_to receive(:redeem_for).with(mandate)
      mandate.voucher_code = ""
      mandate.send(:redeem_voucher)
    end

    it "does not try to redeem a voucher when voucher_code is set to an equal to empty string" do
      expect(Voucher).not_to receive(:redeem_for).with(mandate)
      mandate.voucher_code = "  "
      mandate.send(:redeem_voucher)
    end

    it "adds the voucher id to the mandate" do
      expect(Voucher).to receive(:redeem_for).with(mandate).and_call_original
      expect {
        mandate.update(voucher_code: voucher.code)
      }.to change(mandate, :voucher_id)
        .from(nil).to(voucher.id).and change(voucher, :available_amount).by(-1)
    end

    it "replaces the user source campaign with the voucher campaign" do
      mandate.voucher_code = voucher.code
      mandate.send(:redeem_voucher)
      expect(user.source_data["adjust"]["campaign"]).to eq(voucher.metadata["campaign"])
    end
  end

  context "#send_adjust_accept_tracking", :integration do
    let(:ad_id) { Faker::Internet.device_token }
    let(:clv) { (rand * 100).round }

    before do
      allow_any_instance_of(Domain::Reports::CustomerValue).to receive(:clv).and_return(clv)
    end

    it "sends tracking for correct data for iOS ad ids" do
      mandate = create(
        :mandate,
        state: "in_creation",
        user: create(:user, source_data: {advertiser_ids: {ad_id => "idfa"}})
      )

      expect { mandate.send(:send_adjust_accept_tracking_event) }.to broadcast(:send_adjust_accept_tracking)
    end
  end

  context "#source" do
    it "returns organic if no source data is available" do
      expect(subject.source).to eq("Organic")
    end

    it "returns source network if available" do
      mandate = FactoryBot.build(
        :mandate,
        state: "in_creation",
        user:  FactoryBot.build(:user, source_data: {adjust: {network: "facebook"}})
      )
      expect(mandate.source).to eq("facebook")
    end
  end

  describe "#welcome_call_status" do
    let(:mandate) { create(:mandate) }

    it "returns not_attempted if no mandate welcome call found in the interactions" do
      expect(mandate.welcome_call_status).to eq(:not_attempted)
    end

    it "returns successful if the last welcome call found in the interactions and was in reached state" do
      create(
        :interaction_phone_call,
        call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
        status:    Interaction::PhoneCall::STATUS_REACHED, mandate: mandate
      )
      expect(mandate.welcome_call_status).to eq(:successful)
    end

    it "returns unsuccessful if the last welcome call found in the interactions and was in not reached state" do
      create(
        :interaction_phone_call,
        call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
        status:    Interaction::PhoneCall::STATUS_NOT_REACHED,
        mandate:   mandate
      )
      expect(mandate.welcome_call_status).to eq(:unsuccessful)
    end

    it "returns unsuccessful if the last welcome call found in the interactions and was in need follow up state" do
      create(
        :interaction_phone_call,
        call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
        status:    Interaction::PhoneCall::STATUS_NEED_FOLLOW_UP,
        mandate:   mandate
      )
      expect(mandate.welcome_call_status).to eq(:unsuccessful)
    end

    it "returns successful if more than one welcome call found in the interactions and the last one was in reached state" do
      create(
        :interaction_phone_call,
        call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
        status:    Interaction::PhoneCall::STATUS_NEED_FOLLOW_UP,
        mandate:   mandate
      )

      create(
        :interaction_phone_call,
        call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
        status:    Interaction::PhoneCall::STATUS_REACHED,
        mandate:   mandate
      )

      expect(mandate.welcome_call_status).to eq(:successful)
    end
  end

  describe "#pushable_devices?" do
    let(:mandate) { create(:mandate, user: create(:user)) }
    let(:valid_device) { create(:device) }
    let(:disabled_device) { create(:device, permissions: {push_enabled: false}) }
    let(:device_without_tokens) { create(:device, token: nil, arn: nil) }

    context "when device is pushable" do
      it "returns true" do
        mandate.user.devices = [valid_device]
        expect(mandate.pushable_devices?).to eq(true)
      end
    end

    context "when device isn't pushable" do
      it "returns false on device with_push_enabled? equal false" do
        mandate.user.devices = [disabled_device]
        expect(mandate.pushable_devices?).to eq(false)
      end

      it "returns false on device with no :token and :arn" do
        mandate.user.devices = [device_without_tokens]
        expect(mandate.pushable_devices?).to eq(false)
      end
    end
  end

  context "#new_address_if_changed" do
    let!(:mandate) { create :mandate }

    it "creates an address entry for a newely created mandate" do
      expect(mandate.addresses.count).to eq(1)
    end

    it "does not generate a new entry in the addresses table if mandate address does not change" do
      expect { mandate.save }.not_to change(mandate.addresses, :count)
    end
  end

  describe "#active_recommendations" do
    it "returns only active recommendations" do
      mandate = create(:mandate)
      create(:recommendation, mandate: mandate, dismissed: true)
      active_recommendation = create(:recommendation, mandate: mandate, dismissed: false)

      expect(mandate.active_recommendations).to eq([active_recommendation])
    end
  end

  describe "#owns_product_of_category?" do
    let(:mandate) { create :mandate }
    let(:plan) { create(:plan) }

    context "when product state is in an active state" do
      it "should return true" do
        product = create(:product, :details_available, plan: plan, mandate: mandate)

        expect(mandate.owns_product_of_category?(product.category)).to eq(true)
      end
    end

    context "when the product has no category" do
      it "should return false" do
        create(:product, :customer_provided, plan: nil, mandate: mandate)

        expect(mandate.owns_product_of_category?(plan.category)).to eq(false)
      end
    end

    context "when product state is in customer_provided state" do
      it "should return true" do
        product = create(:product, :customer_provided, plan: plan, mandate: mandate)

        expect(mandate.owns_product_of_category?(product.category)).to eq(true)
      end
    end

    context "when product state is terminated" do
      let(:product) { create(:product, :terminated, mandate: mandate, contract_ended_at: contract_ended_at) }

      context "contract not ended" do
        let(:contract_ended_at) { 2.days.from_now }

        it "should return true" do
          expect(mandate.owns_product_of_category?(product.category)).to eq(true)
        end
      end

      context "contract ended" do
        let(:contract_ended_at) { 2.days.ago }

        it "should return false" do
          expect(mandate.owns_product_of_category?(product.category)).to eq(false)
        end
      end
    end

    context "when product state is not in active state" do
      it "should return false" do
        product = create(:product, :canceled, plan: plan, mandate: mandate)

        expect(mandate.owns_product_of_category?(product.category)).to eq(false)
      end
    end
  end

  # Class Methods

  context "score calculation" do
    let(:mandate) { create(:mandate) }
    let(:plan)    { create(:plan) }

    it "is not defined without recommendations" do
      expect(mandate.score).to be_nil
    end

    context "when all calculation parameters are present" do
      let(:recommendation1) do
        create(:recommendation, mandate: mandate, category: plan.category)
      end
      let(:initial_score) { mandate.score }

      before do
        recommendation1
        initial_score
      end

      it "returns a score when recommendations are present" do
        expect(initial_score).to be 0
      end

      it "returns a score when products are present" do
        create(:product, plan: plan, mandate: mandate)
        mandate.reload
        expect(mandate.score).to be > initial_score
      end

      it "returns a score when recommendations and inquiries with categories are present" do
        inquiry_category = create(:inquiry_category, category: recommendation1.category)
        create(
          :inquiry,
          mandate:            mandate,
          inquiry_categories: [inquiry_category]
        )
        mandate.reload
        raise "test setup wrong" if mandate.inquiries.first.inquiry_categories.count.zero?

        expect(mandate.score).to be > initial_score
      end
    end

    context "when some calculation parameter is missing" do
      it "returns nil if no recommendations are present" do
        create(:product, plan: plan, mandate: mandate)
        expect(mandate.score).to eq nil
      end

      it "returns 0 if no products are present" do
        create(:recommendation, mandate: mandate, category: plan.category)
        expect(mandate.score).to eq 0
      end

      it "returns 0 if at least one inquiry doesn't have a category" do
        create(:recommendation, mandate: mandate, category: plan.category)
        create(:inquiry, mandate: mandate)
        expect(mandate.score).to eq 0
      end
    end
  end

  context "phones" do
    let(:mandate)      { create(:mandate) }
    let(:phone_number) { "+49#{ClarkFaker::PhoneNumber.phone_number}" }

    it "creates a new primary phone record if a phone is passed to mandate params" do
      mandate.phone = phone_number
      mandate.save!
      expect(Phone.count).to eq(1)
    end

    it "gets the primary phone number if exists when phone is called on a mandate" do
      Phone.create(number: phone_number, primary: true, mandate: mandate)
      expect(mandate.phone).to eq(phone_number)
    end

    it "only gets the primary phone number when phone is called on a mandate" do
      Phone.create(number: phone_number, primary: false, mandate: mandate)
      Phone.create(number: phone_number, primary: true, mandate: mandate)
      expect(mandate.phone).to eq(phone_number)
    end

    it "returns nil if no primary phone record does not exist and phone is called on a mandate" do
      expect(mandate.phone).to be_nil
    end

    it "returns the german formatted phone number even if it was passed without the country code prefix" do
      phone_number = ClarkFaker::PhoneNumber.phone_number
      mandate.phone = phone_number
      mandate.save!
      expect(mandate.phone).to eq("+49#{phone_number}")
    end

    it "raises an error when malformed phone number is passed to the mandate" do
      mandate.phone = "not a phone"
      mandate.save
      expect(mandate.errors[:phone].size).to eq(1)
    end

    it "changes the primary phone record if new value is passed to phone and there was a primary phone record" do
      new_phone_number = "+49#{ClarkFaker::PhoneNumber.phone_number}"
      Phone.create(number: phone_number, primary: true, mandate: mandate)
      mandate.phone = new_phone_number
      mandate.save!
      expect(mandate.phone).to eq(new_phone_number)
    end

    it "does not change the primary phone record if same value is passed to phone and there was a primary phone record" do
      Phone.create(number: phone_number, primary: true, mandate: mandate)
      mandate.phone = phone_number
      mandate.save!
      expect(mandate.phone).to eq(phone_number)
    end

    it "removes the primary phone record if nil is passed to phone and there was a primary phone record" do
      Phone.create(number: phone_number, primary: true, mandate: mandate)
      mandate.phone = ""
      mandate.save!
      expect(Phone.count).to eq(0)
    end

    it "does nothing when there is no phone and nil is passed as phone attribute" do
      mandate.phone = ""
      phones = mandate.phones

      expect(phones).not_to receive(:new).with(number: "", primary: true)
      mandate.save!
    end
  end

  describe "#blz_blocked?" do
    it "returns false if blz info missing" do
      mandate = create(:mandate, info: {})
      expect(mandate.blz_blocked?).to eq false
    end

    it "returns false if blz black list is empty" do
      Settings.retirement.blz_black_list = []
      mandate = create(:mandate, info: {"blz" => "04210"})
      expect(mandate.blz_blocked?).to eq false
    end

    it "returns true if blz code into black list" do
      Settings.retirement.blz_black_list = ["04210"]
      mandate = create(:mandate, info: {"blz" => "04210"})
      expect(mandate.blz_blocked?).to eq true
    end
  end

  describe "#products_for_mgt_calculation" do
    let(:user) { create :user, :with_mandate, :direkt_1822 }
    before do
      create(:product, :details_available, mandate: user.mandate)
      create(:product, :under_management, mandate: user.mandate)
      create(:product, :takeover_requested, mandate: user.mandate)
      create(:product, :termination_pending, mandate: user.mandate)
    end
    it "accepts only under_management, takeover_requested, details_available, termination_pending states of product" do
      expect(user.mandate.products.count).to eq 4
      expect(user.mandate.products_for_mgt_calculation.count).to eq 4

      create(:product, :ordered, mandate: user.mandate)
      create(:product, :correspondence, mandate: user.mandate)

      expect(user.mandate.products.count).to eq 6
      expect(user.mandate.products_for_mgt_calculation.count).to eq 4
    end
  end
end
