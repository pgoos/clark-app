# frozen_string_literal: true
# == Schema Information
#
# Table name: api_partners
#
#  id                :integer          not null, primary key
#  name              :string           default(""), not null
#  secret_key        :string           default(""), not null
#  comments          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  salt              :string
#  consumer_key      :string           default(""), not null
#  partnership_ident :string           default(""), not null
#  access_tokens     :jsonb            not null
#  webhook_base_url  :string           default(""), not null
#

require "rails_helper"

RSpec.describe ApiPartner, type: :model do
  let(:ident) {"test"}

  it "has a valid factory" do
    expect(build(:api_partner)).to be_valid
  end

  let(:client) { build(:api_partner) }

  describe "ActiveModel validations" do
    # Basic validations
    it { expect(client).to validate_presence_of(:name) }
    it { expect(client).to validate_presence_of(:consumer_key) }
    it { expect(client).to validate_presence_of(:partnership_ident) }
    it { expect(client).not_to validate_presence_of(:secret_key) }
    it { expect(client).not_to validate_presence_of(:salt) }

    it { expect(client).to validate_uniqueness_of(:name) }
    it { expect(client).to validate_uniqueness_of(:consumer_key) }
    it { expect(client).to validate_uniqueness_of(:partnership_ident) }
    it { expect(client).to validate_uniqueness_of(:secret_key) }

    context "when secret_key isn't empty" do
      let(:client) { build(:api_partner, secret_key: "foo") }
      it { expect(client).to validate_presence_of(:salt) }
    end
  end

  describe "public instance methods" do
    context "responds to its methods" do
      it { expect(client).to respond_to(:save_secret_key!) }
      it { expect(client).to respond_to(:valid_secret_key?) }
      it { expect(client).to respond_to(:update_access_token_for_instance!) }
      it { expect(client).to respond_to(:clear_access_tokens!) }
    end

    context "executes methods correctly" do
      let(:client) { create(:api_partner) }

      context "#save_secret_key!" do
        it "create the salt for hashing and updates secret_key" do
          old_secret_key = client.secret_key
          client.save_secret_key!("raw_secret_key")
          client.reload
          expect(client.secret_key).not_to eq(old_secret_key)
        end

        it "updates salt" do
          old_salt = client.salt
          client.save_secret_key!("raw_secret_key")
          client.reload
          expect(client.salt).not_to eq(old_salt)
        end
      end

      context "#valid_secret_key?" do
        before do
          client.save_secret_key!("raw_secret_key")
          client.reload
        end

        it "returns true if hashes are equal" do
          expect(client.valid_secret_key?("raw_secret_key")).to be_truthy
        end

        it "returns false if hashes aren't equal" do
          expect(client.valid_secret_key?("wrong_secret_key")).to be_falsy
        end
      end

      context "#update_access_token_for_instance!" do
        it "generates a new access token for the instance" do
          client.update_access_token_for_instance!(ident)
          old_access_token = client.access_token_for_instance(ident)["value"]

          client.update_access_token_for_instance!(ident)
          client.reload

          new_access_token = client.access_token_for_instance(ident)["value"]
          expect(new_access_token).not_to eq(old_access_token)
        end

        it "updates expire timestamp" do
          Timecop.freeze(Date.yesterday)

          client.update_access_token_for_instance!(ident)
          old_expires_at = client.access_token_for_instance(ident)["expires_at"]

          Timecop.return

          client.update_access_token_for_instance!(ident)
          client.reload

          new_expires_at = client.access_token_for_instance(ident)["expires_at"]
          expect(new_expires_at).not_to eq(old_expires_at)
        end
      end

      context "#clear_access_tokens!" do
        before do
          client.clear_access_tokens!
          client.reload
        end

        it "clears access_tokens" do
          expect(client.access_tokens).to eq([])
        end
      end
    end
  end

  describe "public class methods" do
    context "responds to its methods" do
      it { expect(described_class).to respond_to(:generate_random_key) }
      it { expect(described_class).to respond_to(:by_access_token) }
    end

    context "executes methods correctly" do
      context "self.generate_random_key" do
        it { expect(described_class.generate_random_key.length).to eq(64) }
        it { expect(described_class.generate_random_key(16).length).to eq(32) }
      end
    end
  end
end
