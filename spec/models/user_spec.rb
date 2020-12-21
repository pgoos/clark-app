# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  created_at             :datetime
#  updated_at             :datetime
#  state                  :string
#  info                   :hstore
#  referral_code          :string
#  inviter_id             :integer
#  inviter_code           :string
#  subscriber             :boolean          default(TRUE)
#  mandate_id             :integer
#  source_data            :jsonb
#  paid_inviter_at        :datetime
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#

require "rails_helper"

RSpec.describe User, type: :model do
  subject { user }

  let(:user) { FactoryBot.build(:user) }

  it { is_expected.to be_valid }
  it_behaves_like "a commentable model"
  it_behaves_like "an activatable model"
  it_behaves_like "an auditable model"
  it_behaves_like "an ad attributable model"
  it_behaves_like "a source namable model"
  it_behaves_like "an event observable model"
  it_behaves_like "a source partnerable model"
  it_behaves_like "a documentable"

  it { is_expected.to be_a(PasswordGenerator) }

  describe "scopes" do
    let!(:user1) { create(:user, id: 1, email: "peter@test.clark.de") }
    let!(:user2) { create(:user, id: 2, email: "uli@test.clark.de") }

    it_behaves_like "a model providing a contains-scope on", :email

    it ".by_id" do
      expect(User.by_id(1)).to eq [user1]
    end

    describe ".by_id_email_cont" do
      it "when searching by id" do
        expect(User.by_id_email_cont("1")).to eq([user1])
      end

      it "when searching by email" do
        expect(User.by_id_email_cont("uli")).to eq([user2])
      end
    end

    it ".with_identities" do
      user1.identities << create(:identity)

      expect(User.with_identities).to eq([user1])
    end

    it ".by_oauth" do
      user1.identities << create(:identity)
      user2.identities << create(:identity)

      expect(User.by_oauth(double(provider: user1.identities.first.provider,
                                  uid: user1.identities.first.uid))).to eq([user1])
    end

    describe ".unconfirmed_with_mandate" do
      it "finds users that are not confirmed and the mandate was created at least a day ago" do
        user = create(:user, confirmed_at: nil)
        create(:mandate, updated_at: 2.days.ago, state: "created", user: user)

        expect(User.unconfirmed_with_mandate).to match_array([user])
      end

      it "ignores confirmed users" do
        user = create(:user, confirmed_at: Time.now.in_time_zone)
        create(:mandate, updated_at: 2.days.ago, state: "created", user: user)
        expect(User.unconfirmed_with_mandate).not_to include(user)
      end

      it "ignores users when the mandate was completed less then a day ago" do
        user = create(:user, confirmed_at: nil)
        create(:mandate, updated_at: 10.minutes.ago, state: "created", user: user)
        expect(User.unconfirmed_with_mandate).not_to include(user)
      end

      it "ignores users when the mandate was not completed" do
        user = create(:user, confirmed_at: nil)
        create(:mandate, updated_at: 2.days.ago, state: "in_creation", user: user)
        expect(User.unconfirmed_with_mandate).not_to include(user)
      end

      it "ignores users without mandates" do
        user = create(:user, confirmed_at: nil)
        expect(User.unconfirmed_with_mandate).not_to include(user)
      end
    end

    describe ".unpayed_inviters" do
      let!(:user3) { create(:user) }

      context "when users that are inviters and not paid for the invitee" do
        before do
          user2.inviter_id = user1.id
          user2.paid_inviter_at = nil
          user1.save!
          user2.save!
        end

        it "returns inviters not payed yet" do
          user3.inviter_id = user1.id
          user2.save!
          user3.save!
          user1.save!

          unpayed_inviters = User.unpayed_inviters
          expect(unpayed_inviters).not_to be_nil
          expect(unpayed_inviters).to include(user1)
          expect(unpayed_inviters).not_to include(user2, user3)
        end

        it "returns multuple inviters if present and are not payed" do
          user3.inviter_id = user2.id
          user3.save!

          unpayed_inviters = User.unpayed_inviters
          expect(unpayed_inviters).not_to be_nil
          expect(unpayed_inviters).to include(user1, user2)
          expect(unpayed_inviters).not_to include(user3)
        end
      end

      context "when users that are inviters and are already paid for the invitees" do
        before do
          user2.inviter_id = user1.id
          user2.paid_inviter_at = Time.zone.now
          user1.save!
          user2.save!
        end

        it "no inviters are returned since they are all paid" do
          user3.inviter_id = user1.id
          user3.paid_inviter_at = Time.zone.now
          user2.save!
          user3.save!
          user1.save!

          unpayed_inviters = User.unpayed_inviters
          expect(unpayed_inviters).to be_empty
        end

        it "returns only inviters that are not paid" do
          user3.inviter_id = user2.id
          user3.paid_inviter_at = nil
          user2.save!
          user3.save!

          unpayed_inviters = User.unpayed_inviters
          expect(unpayed_inviters).not_to be_nil
          expect(unpayed_inviters).to include(user2)
          expect(unpayed_inviters).not_to include(user1, user3)
        end
      end

      context "when a user somehow ended up inviting themself" do
        it "does not show the invitee as part of the self inviter" do
          user3.inviter_id = user3.id
          user3.paid_inviter_at = nil
          user3.save!
          unpayed_inviters = User.unpayed_inviters
          expect(unpayed_inviters).to be_empty
        end

        it "does return valid invitees but skips the self inviter" do
          user3.inviter_id = user3.id
          user3.paid_inviter_at = nil
          user3.save!
          user2.inviter_id = user3.id
          user2.paid_inviter_at = nil
          user2.save!
          unpayed_inviters = User.unpayed_inviters
          expect(unpayed_inviters).to include(user3)
        end
      end

      it "returns empty when no inviter present" do
        expect(User.unpayed_inviters).to be_empty
      end
    end
  end

  it { expect(subject).to belong_to(:mandate) }
  it { expect(subject).to belong_to(:inviter).class_name("User").with_foreign_key("inviter_id") }
  it { expect(subject).to have_many(:identities).dependent(:destroy) }
  it { expect(subject).to have_many(:follow_ups).dependent(:destroy) }
  it { expect(subject).to have_many(:executed_business_events).class_name("BusinessEvent") }
  it { is_expected.to accept_nested_attributes_for(:mandate) }

  it_behaves_like "a model with email validation on", :email
  it_behaves_like "a model requiring a password only for new records"

  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  context "password complexity" do
    it "requires a number" do
      user = FactoryBot.build(:user, password: "TestTest")
      expect(user).not_to be_valid
      expect(user.errors[:password])
        .to include(I18n.t("activerecord.errors.models.user.password_complexity"))
    end

    it "requires an uppercase letter" do
      user = FactoryBot.build(:user, password: "test1234")

      expect(user).not_to be_valid
      expect(user.errors[:password])
        .to include(I18n.t("activerecord.errors.models.user.password_complexity"))
    end

    it "requires a lowercase letter" do
      user = FactoryBot.build(:user, password: "TEST1234")

      expect(user).not_to be_valid
      expect(user.errors[:password])
        .to include(I18n.t("activerecord.errors.models.user.password_complexity"))
    end

    it "shows the devise error when password is complex enough but not long enough" do
      user = FactoryBot.build(:user, password: "Ab7")

      expect(user).not_to be_valid
      expect(user.errors[:password])
        .not_to include(I18n.t("activerecord.errors.models.user.password_complexity"))
    end

    it "is valid with lower-, uppercase and numer" do
      user = FactoryBot.build(:user, password: Settings.seeds.default_password)

      expect(user).to be_valid
      expect(user.errors[:password]).to be_empty
    end

    it "does not allow passwords with 7 chars (old behavior we had to build for iOS App)" do
      user = FactoryBot.build(:user, password: "Test123")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end
  end

  context "source data validations" do
    it "should be valid for {}" do
      subject.source_data = {}
      expect(subject).to be_valid
    end

    it "should not be valid for nil" do
      subject.source_data = nil
      expect(subject).not_to be_valid
    end

    it "should provide an error message if nil" do
      subject.source_data = nil
      subject.valid?
      expect(subject.errors.messages[:source_data].first).not_to match(/translation missing:/)
    end
  end

  context "#update_by_lead!" do
    let(:source_data) { {} }

    let(:existing_user) do
      create(
        :user,
        :with_mandate,
        source_data: source_data
      )
    end

    let(:lead_source_data) do
      {"adjust" => {"network" => "partner1"}}
    end

    let(:lead) { create(:lead, :with_mandate, source_data: lead_source_data) }
    let(:from_lead_attributes) { %w[campaign terms id created_at] }

    it "should use the lead's source data if the user's lead is empty" do
      existing_user.update_by_lead!(lead)
      expect(existing_user.source_data[:adjust]).to eq(lead_source_data[:adjust])
      expect(existing_user.source_data["from_lead"].keys).to match_array(from_lead_attributes)
      expect(existing_user.source_data["from_lead"]["id"]).to eq(lead.id)
      expect(existing_user.source_data["from_lead"]["campaign"]).to eq(lead.campaign)
      expect(existing_user.source_data["from_lead"]["terms"]).to eq(lead.terms)
      expect(existing_user.source_data["from_lead"]["created_at"].to_date).to eq(lead.created_at.to_date)
    end

    it "should persist the changes" do
      existing_user.update_by_lead!(lead)
      existing_user.reload
      expect(existing_user.source_data[:adjust]).to eq(lead_source_data[:adjust])
      expect(existing_user.source_data["from_lead"].keys).to match_array(from_lead_attributes)
    end

    it "should not overwrite an existing network value" do
      expected_partner = "existing_partner"
      source_data["adjust"] = {"network" => expected_partner}
      existing_user.update_by_lead!(lead)
      expect(existing_user.adjust["network"]).to eq(expected_partner)
    end

    context "recursive merge of source_data" do
      it "should merge the network also, if the adjust key was previously set to the user" do
        source_data["adjust"] = {}
        existing_user.update_by_lead!(lead)
        expect(existing_user.source_data[:adjust]).to eq(lead_source_data[:adjust])
        expect(existing_user.source_data["from_lead"].keys).to match_array(from_lead_attributes)
      end
    end

    context "remember device" do
      let(:t_user) { 1.hour.ago }
      let(:t_new)  { t_user.advance(seconds: +1) }

      let(:device_lead) { create(:device_lead, :with_mandate) }
      let(:new_device)  { create(:device, created_at: t_new, lead: device_lead) }
      let(:user_device) do
        d = create(:device, created_at: t_user, user: existing_user)
        existing_user.update!(installation_id: d.installation_id)
        d
      end

      it "should connect the new device to the user" do
        new_device
        existing_user.update_by_lead!(device_lead)
        expect(existing_user.devices).to include(new_device)
      end

      it "should keep the old device" do
        new_device
        existing_user.update_by_lead!(device_lead)
        expect(existing_user.devices).to include(user_device)
      end
    end

    context "tracking" do
      it "should migrate tracking visits" do
        tracking_visit1 = create(:tracking_visit, mandate: lead.mandate)
        tracking_visit2 = create(:tracking_visit, mandate: lead.mandate)

        existing_user.update_by_lead!(lead)

        visits = Tracking::Visit.where(mandate: existing_user.mandate).pluck(:id)
        expect(visits).to include(tracking_visit1.id, tracking_visit2.id)
      end

      it "should migrate tracking events" do
        tracking_event1 = create(:tracking_event, mandate: lead.mandate)
        tracking_event2 = create(:tracking_event, mandate: lead.mandate)

        existing_user.update_by_lead!(lead)

        events = Tracking::Event.where(mandate: existing_user.mandate).pluck(:id)
        expect(events).to include(tracking_event1.id, tracking_event2.id)
      end

      it "should migrate adjust events" do
        attributes    = {mandate: lead.mandate, params: {key: "value"}}
        adjust_event1 = create(:tracking_adjust_event, attributes)
        adjust_event2 = create(:tracking_adjust_event, attributes)

        existing_user.update_by_lead!(lead)

        events = Tracking::AdjustEvent.where(mandate: existing_user.mandate).pluck(:id)
        expect(events).to include(adjust_event1.id, adjust_event2.id)
      end

      it "should migrate business events" do
        business_event1 = create(:business_event, audited_mandate: lead.mandate)
        business_event2 = create(:business_event, audited_mandate: lead.mandate)

        existing_user.update_by_lead!(lead)

        events = BusinessEvent.by_audited_mandate(existing_user.mandate).pluck(:id)
        expect(events).to include(business_event1.id, business_event2.id)
      end

      def expect_not_to_migrate_tracking_data
        expect(Tracking::Visit).not_to receive(:by_mandate)
        expect(Tracking::Event).not_to receive(:by_mandate)
        expect(Tracking::AdjustEvent).not_to receive(:by_mandate)
        expect(BusinessEvent).not_to receive(:by_audited_mandate)
      end

      it "may NOT try to reattribute, if the lead's mandate is nil" do
        lead_no_mandate = create(:device_lead, mandate: nil)
        expect_not_to_migrate_tracking_data
        existing_user.update_by_lead!(lead_no_mandate)
      end

      it "may NOT try to reattribute, if the user's mandate is nil" do
        user_no_mandate = create(:user, mandate: nil)
        expect_not_to_migrate_tracking_data
        user_no_mandate.update_by_lead!(lead)
      end

      it "may NOT try to reattribute, if both the lead's and the user's mandate are nil" do
        lead_no_mandate = create(:device_lead, mandate: nil)
        user_no_mandate = create(:user, mandate: nil)
        expect_not_to_migrate_tracking_data
        user_no_mandate.update_by_lead!(lead_no_mandate)
      end

      it "should not try to reattribute, if both mandates are the same" do
        lead_same_mandate = create(:lead, mandate: existing_user.mandate)
        expect_not_to_migrate_tracking_data
        existing_user.update_by_lead!(lead_same_mandate)
      end
    end

    context "inviter_code" do
      let(:inviter_code) { "inviter_code_#{rand}" }

      it "should set the inviter code" do
        lead = create(:lead, :with_mandate, inviter_code: inviter_code)
        existing_user.update_by_lead!(lead)
        expect(existing_user.inviter_code).to eq(inviter_code)
      end

      it "should not overwrite the inviter code with a new value" do
        lead = create(:lead, :with_mandate, inviter_code: "wrong")
        existing_user.update!(inviter_code: inviter_code)
        existing_user.update_by_lead!(lead)
        expect(existing_user.inviter_code).to eq(inviter_code)
      end

      it "should not link to any existing referee user" do
        lead = create(:lead, :with_mandate, inviter_code: inviter_code)
        existing_user.update_by_lead!(lead)
        expect(existing_user.inviter).to be_nil
      end

      context "when inviter code links to an existing referee user" do
        let(:inviter_user) { create(:user, :with_mandate, referral_code: inviter_code) }

        before do
          inviter_user
        end

        it "should have the correct inviter id" do
          lead = create(:lead, :with_mandate, inviter_code: inviter_code)
          existing_user.update_by_lead!(lead)
          expect(existing_user.inviter).to eq(inviter_user)
        end
      end
    end
  end

  context "update installation id by lead" do
    let(:t_user) { 1.hour.ago }
    let(:t_old)  { t_user.advance(seconds: -1) }
    let(:t_new)  { t_user.advance(seconds: +1) }

    let(:existing_user) { create(:user, :with_mandate) }

    let(:user_device) do
      d = create(:device, created_at: t_user, user: existing_user)
      existing_user.update!(installation_id: d.installation_id)
      d
    end

    let(:lead_new_device) { create(:device_lead, :with_mandate) }
    let(:lead_old_device) { create(:device_lead, :with_mandate) }

    let(:new_device) { create(:device, created_at: t_new, lead: lead_new_device) }
    let(:old_device) { create(:device, created_at: t_old, lead: lead_old_device) }

    it "should update the installation id to the newer one" do
      user_device
      new_device
      existing_user.update_by_lead!(lead_new_device)
      expect(existing_user.installation_id).to eq(new_device.installation_id)
    end

    it "should set the installation id if none before" do
      new_device
      existing_user.update_by_lead!(lead_new_device)
      expect(existing_user.installation_id).to eq(new_device.installation_id)
    end

    it "should not update the installation id to an older one" do
      user_device
      old_device
      existing_user.update_by_lead!(lead_old_device)
      expect(existing_user.installation_id).to eq(user_device.installation_id)
    end

    it "should not set the installation id to nil" do
      user_device
      existing_user.update_by_lead!(create(:lead, installation_id: nil))
      expect(existing_user.installation_id).to eq(user_device.installation_id)
    end
  end

  describe "#unconfirm" do
    subject { user.unconfirm }

    context "when user is confirmed" do
      before do
        user.confirmation_sent_at = DateTime.now.in_time_zone
        user.confirm
      end

      it { expect { subject }.to change(user, :confirmed_at).to(nil) }
    end

    context "when user is unconfirmed" do
      before { user.confirmed_at = nil }

      it { expect { subject }.not_to change(user, :confirmed_at) }
    end
  end

  describe "#add_identity" do
    subject { user.add_identity(auth) }

    let(:auth) { double(provider: provider, uid: uid) }

    before { user.save }

    context "when provider is given" do
      let(:provider) { "auth provider" }

      context "when uid is given" do
        let(:uid) { "auth uid" }

        it { expect { subject }.to change { user.identities.count }.by(1) }
      end

      context "when uid is not given" do
        let(:uid) { nil }

        it { expect { subject }.not_to change { user.identities.count } }
      end
    end

    context "when provider is not given" do
      let(:provider) { nil }

      context "when uid is given" do
        let(:uid) { "auth uid" }

        it { expect { subject }.not_to change { user.identities.count } }
      end

      context "when uid is not given" do
        let(:uid) { nil }

        it { expect { subject }.not_to change { user.identities.count } }
      end
    end
  end

  describe "#invited_by" do
    subject { user.invited_by(inviter, inviter_code) }

    let(:inviter_code) { nil }

    context "when inviter is given" do
      let(:inviter) { User.new }

      it { expect { subject }.to change(user, :inviter).from(nil).to(inviter) }
    end

    context "when no inviter is given" do
      let(:inviter) { nil }

      it { expect { subject }.not_to change(user, :inviter) }
    end

    context "when inviter code is given" do
      let(:inviter) { User.new }
      let(:inviter_code) { "123" }

      it { expect { subject }.to change(user, :inviter_code).from(nil).to(inviter_code) }
    end
  end

  describe "#password_required?" do
    subject { user.password_required? }

    context "when user is new record" do
      let(:user) { build :user }

      it { is_expected.to be true }
    end

    context "when user is existing record" do
      let(:user) do
        build_stubbed :user, password: password, password_confirmation: password_confirmation
      end
      let(:password)              { nil }
      let(:password_confirmation) { nil }

      it { is_expected.to be false }

      context "when password is set" do
        let(:password) { Settings.seeds.default_password }

        it { is_expected.to be true }
      end

      context "when password is set" do
        let(:password_confirmation) { "password_confirmation" }

        it { is_expected.to be true }
      end
    end
  end

  describe "#mandate?" do
    subject { user.mandate? }

    context "when user has a mandate" do
      before { user.mandate = build :mandate }

      it { is_expected.to be true }
    end

    context "when user has no mandate" do
      before { user.mandate = nil }

      it { is_expected.to be false }
    end
  end

  describe "#name" do
    subject { user.name }

    let(:email) { "email@test.clark.de" }

    before { user.email = email }

    context "when mandate is given" do
      before { user.mandate = build :mandate, first_name: first_name }

      context "when mandate.first_name is set" do
        let(:first_name) { "first name" }

        it { is_expected.to eq(first_name) }
      end

      context "when mandate.first_name is not set" do
        let(:first_name) { nil }

        it { is_expected.to eq(email) }
      end
    end

    context "when no mandate is given" do
      before { user.mandate = nil }

      it { is_expected.to eq(email) }
    end
  end

  describe "#welcome_from" do
    let(:now) { Time.zone.parse("2010-01-03 10:00:00") }
    let(:midnight) { Time.zone.parse("2010-01-03 00:00:00") }
    let(:created_at) { Time.zone.parse("2010-01-02 00:10:00") }

    let(:user) do
      create(
        :user,
        created_at: created_at,
        last_sign_in_at: last_sign_in_at
      )
    end

    before { Timecop.freeze(now) }

    after { Timecop.return }

    context "when #last_sign_in_at is not empty" do
      context "when #last_sign_in_at > 00:00 AM" do
        let(:last_sign_in_at) { Time.zone.parse("2010-01-03 00:00:01") }

        it "returns 00:00 AM" do
          expect(user.welcome_from).to eq(midnight)
        end
      end

      context "when #last_sign_in_at <= 00:00 AM" do
        let(:last_sign_in_at) { Time.zone.parse("2010-01-02 23:59:59") }

        it "returns #last_sign_in_at" do
          expect(user.welcome_from).to eq(last_sign_in_at)
        end
      end
    end

    context "when #last_sign_in_at is empty" do
      let(:last_sign_in_at) { nil }

      it "returns 00:00 AM" do
        expect(user.welcome_from).to eq(created_at)
      end
    end
  end

  describe "#be_app_user?" do
    it "is true if the user has a device" do
      user.devices << create(:device)

      expect(user).to be_app_user
    end

    it "is false if the user does not have a device" do
      user.devices = []
      expect(user).not_to be_app_user
    end
  end

  describe "#active_for_authentication?" do
    subject { user.active_for_authentication? }

    let(:user) { FactoryBot.build(:user, state: state) }

    context "when user is active" do
      let(:state) { "active" }

      it { is_expected.to be true }
    end

    context "when user is inactive" do
      let(:state) { "inactive" }

      it { is_expected.to be false }
    end
  end

  describe ".find_for_oauth" do
    subject { User.find_for_oauth(auth) }

    let(:provider) { "provider" }
    let(:uid)      { "uid" }
    let(:auth)     { double(provider: provider, uid: uid, info: {}) }

    before do
      @random_user = create :user,
                            identities: [create(:identity, provider: "some other provider",
                                                           uid: "some other uid")]
    end

    context "when matching user exists" do
      before do
        @matching_user = create :user, identities: [create(:identity, provider: provider, uid: uid)]
      end

      it { is_expected.to eq(@matching_user) }
    end

    context "when no matching user exists" do
      it { is_expected.to be nil }
    end
  end

  describe ".create_by_oauth" do
    subject { User.create_by_oauth(auth, inviter, inviter_code, create_mandate) }

    let(:auth) do
      double(provider: "provider", uid: "uid", info: double(email: email,
                                                            first_name: "Clark", last_name: "Kent", birthday: "01/01/1980", gender: "male"))
    end

    let(:inviter)        { nil }
    let(:inviter_code)   { nil }
    let(:create_mandate) { true }

    before { allow_any_instance_of(User).to receive(:create_or_update).and_return(true) }

    context "when auth contains email" do
      let(:email) { "email@test.clark.de" }

      context "when no inviter is set" do
        let(:inviter) { nil }

        it { is_expected.to be_valid }
        it { expect(subject.inviter).to be nil }
      end

      context "when inviter is set" do
        let(:inviter) { build :user }

        it { is_expected.to be_valid }
        it { expect(subject.inviter).to eq inviter }
      end

      context "when inviter_code is given" do
        let(:inviter_code) { "bla" }

        it { expect(subject.inviter_code).to eq inviter_code }
      end
    end

    context "when auth contains no email" do
      let(:email) { nil }

      it { expect(subject.errors[:email].size).to be 1 }
    end

    context "mandate" do
      let(:email) { "email@test.clark.de" }

      it "creates a mandate with auth data" do
        expect(subject.mandate.first_name).to eq("Clark")
        expect(subject.mandate.last_name).to eq("Kent")
        expect(subject.mandate.gender).to eq("male")
        expect(subject.mandate.birthdate.to_date).to eq(Date.new(1980, 1, 1))
      end

      context "it is not created when requested" do
        let(:create_mandate) { false }

        it { expect(subject.mandate).to be_nil }
      end
    end
  end

  describe "#opted_out_from_app_tracking?" do
    context "has opted-out device" do
      before do
        create(:device, user: subject, permissions: {tracking: false})
      end

      it "should return true" do
        expect(subject.opted_out_from_app_tracking?).to eq(true)
      end

      context "multiple devices" do
        before do
          create(:device, user: subject, permissions: {tracking: true})
        end

        it "should return true even only one device is opted out" do
          expect(subject.opted_out_from_app_tracking?).to eq(true)
        end
      end
    end

    context "has no opted-out device" do
      before do
        create(:device, user: subject, permissions: {tracking: true})
        create(:device, user: subject, permissions: {tracking: true})
      end

      it "should return false" do
        expect(subject.opted_out_from_app_tracking?).to eq(false)
      end
    end
  end

  describe ".first_or_create_by_oauth" do
    subject { User.first_or_create_by_oauth(auth, inviter, inviter_code) }

    let(:provider) { "provider" }
    let(:uid)      { "uid" }
    let(:email)    { "email@test.clark.de" }

    let(:auth) do
      double(
        provider: provider,
        uid: uid,
        info: double(email: email, first_name: "Clark", last_name: "Kent",
                     birthday: "01/01/1980", gender: "male")
      )
    end

    let(:inviter)      { nil }
    let(:inviter_code) { nil }

    context "when existing user is found by oauth identity" do
      before do
        @matching_user = create :user,
                                identities: [create(:identity, provider: provider, uid: uid)]
      end

      it { is_expected.to eq @matching_user }
      it { expect { subject }.not_to change(User, :count) }
    end

    context "when no existing user is found by oauth identity" do
      context "when a user exists with the same email provided by oauth" do
        before { @matching_user = create :user, email: email }

        it { is_expected.to eq @matching_user }
        it { expect { subject }.to change { @matching_user.identities.count }.by(1) }
        it { expect { subject }.not_to change(User, :count) }
      end

      context "when no user exists with the same email provided by oauth" do
        it { expect { subject }.to change(User, :count).by(1) }
        it { is_expected.to be_confirmed }

        context "when inviter_code is given" do
          let(:inviter_code) { "bla" }

          it { expect(subject.inviter_code).to eq inviter_code }
        end
      end
    end
  end

  context "source data default behavior" do
    it "defaults to {}" do
      expect(subject.source_data).to eq({})
    end

    it "can set source data values" do
      expected_source_data = {"key1" => "value1"}
      subject.source_data = expected_source_data
      expect(subject.source_data).to eq(expected_source_data)
    end
  end
end
