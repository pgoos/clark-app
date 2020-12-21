# frozen_string_literal: true
# == Schema Information
#
# Table name: leads
#
#  id                    :integer          not null, primary key
#  email                 :string
#  subscriber            :boolean          default(TRUE)
#  terms                 :string
#  campaign              :string
#  registered_with_ip    :inet
#  infos                 :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  mandate_id            :integer
#  confirmed_at          :datetime
#  installation_id       :string
#  source_data           :jsonb
#  state                 :string           default("active")
#  inviter_code          :string
#  restore_session_token :string
#

require "rails_helper"

RSpec.describe Lead, type: :model do
  # Setup

  let(:subject) { create(:lead) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"
  it_behaves_like "an ad attributable model"
  it_behaves_like "an activatable model"
  it_behaves_like "a source namable model"
  it_behaves_like "a source partnerable model"
  it_behaves_like "a documentable"

  # State Machine
  # Scopes
  # Associations

  it { expect(subject).to have_many(:executed_business_events).class_name("BusinessEvent") }
  it { expect(subject).to belong_to(:mandate) }
  it do
    expect(subject)
      .to have_many(:devices).with_foreign_key(:installation_id).with_primary_key(:installation_id)
  end

  # Nested Attributes
  # Validations

  %i[email terms campaign registered_with_ip].each do |field|
    it { expect(subject).to validate_presence_of(field) }
  end

  it_behaves_like "a model with email validation on", :email

  context "validate email also if not required" do
    it "should not be valid for a broken mail, even if mail is not required" do
      subject.source_data["anonymous_lead"] = true
      subject.email = "wrong"
      expect(subject).not_to be_valid
    end

    it "should be valid for a propper mail, if mail is not required" do
      subject.source_data["anonymous_lead"] = true
      subject.email = "this.is@valid.com"
      expect(subject).to be_valid
    end

    it "should not be valid for a broken mail, if mail is required" do
      subject.source_data["anonymous_lead"] = false
      subject.email = "wrong"
      expect(subject).not_to be_valid
    end

    it "should be valid for a propper mail, if mail is required" do
      subject.source_data["anonymous_lead"] = false
      subject.email = "this.is@valid.com"
      expect(subject).to be_valid
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

  context "extra email validation" do
    it "does allow another signup with a +something in the mail" do
      create(:lead, email: "hans.wurst@clark.de")

      another_lead = FactoryBot.build(:lead, email: "hans.wurst+nochmal@clark.de")

      expect(another_lead).to be_valid
      expect(another_lead.errors[:email].count).to eq(0)
    end

    it "does allow another signup with a +something in the mail" do
      create(:lead, email: "hans.wurst+erstesmal@clark.de")

      another_lead = FactoryBot.build(:lead, email: "hans.wurst+nochmal@clark.de")

      expect(another_lead).to be_valid
      expect(another_lead.errors[:email].count).to eq(0)
    end

    it "does not allow another signup with a +something in the mail" do
      create(:lead, email: "hans.wurst+erstesmal@clark.de")

      another_lead = FactoryBot.build(:lead, email: "hans.wurst@clark.de")

      expect(another_lead).to be_valid
      expect(another_lead.errors[:email].count).to eq(0)
    end

    it "does allow a similar email address" do
      create(:lead, email: "hans.wurstmann@clark.de")

      another_lead = FactoryBot.build(:lead, email: "hans.wurst@clark.de")

      expect(another_lead).to be_valid
    end

    it "does not allow emails that are used by a user" do
      create(:user, email: "hans.wurst@clark.de")

      another_lead = FactoryBot.build(:lead, email: "hans.wurst@clark.de")

      expect(another_lead).not_to be_valid
      expect(another_lead.errors[:email].count).to eq(1)
      expect(another_lead.errors[:email].first).to eq(I18n.t("activerecord.errors.models.lead.user_account_exist"))
    end

    it "does allow emails that are used by a user when using a +" do
      create(:user, email: "hans.wurst@clark.de")

      another_lead = FactoryBot.build(:lead, email: "hans.wurst+gibmirdengratiskaffee@clark.de")

      expect(another_lead).to be_valid
      expect(another_lead.errors[:email].count).to eq(0)
    end

    it "does not allow mails from some known fake mail providers" do
      expect(FactoryBot.build(:lead, email: "hans.wurst@maileater.com")).not_to be_valid
      expect(FactoryBot.build(:lead, email: "hans.wurst@trashmail.com")).not_to be_valid
      expect(FactoryBot.build(:lead, email: "hans.wurst@antispam.de")).not_to be_valid
      expect(FactoryBot.build(:lead, email: "hans.wurst@dontsendmespam.de")).not_to be_valid
      expect(FactoryBot.build(:lead, email: "hans.wurst@sandelf.de")).not_to be_valid
    end
  end

  # Callbacks
  # Instance Methods

  it "generates a token based on email and id" do
    token = subject.token_for_confirmation
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0, 32],
                                                Rails.application.secrets.secret_key_base)

    expect(crypt.decrypt_and_verify(token))
      .to eq("{\"lead_id\":#{subject.id},\"email\":\"#{subject.email}\"}")
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

  # Class Methods

  context "update_subscriber_flag_by_token" do
    it "updates the subscriber flag for a given token" do
      lead  = create(:lead, subscriber: false)
      token = lead.token_for_confirmation

      expect {
        Lead.update_subscriber_flag_by_token(token, true)
      }.to change { Lead.where(subscriber: true).count }.by(1)

      lead.reload
      expect(lead.subscriber).to be_truthy
    end

    it "does not die when an illegal token was passed" do
      expect {
        Lead.update_subscriber_flag_by_token("something totally not decryptable", true)
      }.not_to raise_error
    end

    it "does not die if the json inside the encrypted token is invalid" do
      crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0, 32],
                                                  Rails.application.secrets.secret_key_base)
      token = crypt.encrypt_and_sign("{[,not json;?")
      expect {
        Lead.update_subscriber_flag_by_token(token, true)
      }.not_to raise_error
    end
  end
end
