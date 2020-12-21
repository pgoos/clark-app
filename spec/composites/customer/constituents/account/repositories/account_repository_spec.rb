# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/repositories/account_repository"

RSpec.describe Customer::Constituents::Account::Repositories::AccountRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#find_by" do
    it "returns entity with aggregated data" do
      customer = create(:customer, :self_service)
      account = repo.find_by(customer_id: customer.id)
      expect(account).to be_kind_of Customer::Constituents::Account::Entities::Account
      expect(account.id).to eq User.find_by!(mandate_id: customer.id).id
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find_by(customer_id: 999)).to be_nil
      end
    end
  end

  describe "#find_by_email" do
    context "when email exists" do
      it "returns true" do
        account = create(:account)
        expect(repo.email_exists?(account.email)).to eq(true)
      end

      it "lookup is case-insensitive" do
        create(:account, email: "foo@bar.com")
        expect(repo.email_exists?("fOO@baR.com")).to eq(true)
      end
    end

    context "when email does not exist" do
      it "returns false" do
        expect(repo.email_exists?("invalid@fake.com")).to eq(false)
      end
    end
  end

  describe "#find_by_reset_password_token" do
    context "when reset_password_token exists" do
      it "returns account" do
        user = create(:user, :with_mandate)
        raw_token = user.send(:set_reset_password_token)
        account = repo.find_by_reset_password_token(raw_token)
        expect(account.customer_id).to eq(user.mandate_id)
      end
    end

    context "when reset_password_token does not exist" do
      it "returns nil" do
        account = repo.find_by_reset_password_token("unknown-token")
        expect(account).to be_nil
      end
    end
  end

  describe "#find_by_credentials" do
    it "returns nil when email is not found" do
      user = repo.find_by_credentials("foo@bar", "Test1234")
      expect(user).to be_nil
    end

    it "returns nil when email is found but password is invalid" do
      create(:user, :with_mandate, email: "foo@bar", password: "Test1234")
      user = repo.find_by_credentials("foo@bar", "Test12345")
      expect(user).to be_nil
    end

    it "returns user if credentials are valid" do
      ouser = create(:user, :with_mandate, email: "foo@bar", password: "Test1234")
      user = repo.find_by_credentials("foo@bar", "Test1234")
      expect(user).not_to be_nil
      expect(user.id).to eq ouser.id
    end
  end

  describe "#update!" do
    let(:account) { create(:account) }

    context "with valid params" do
      let(:params) { { password: "Test1234", email: "new@totally-new.de" } }

      it "udpates account and returns true" do
        expect(repo.update!(account.id, params)).to eq(true)

        user = User.find(account.id)
        expect(user.email).to eq(params[:email])
        expect(user.valid_password?(params[:password])).to eq(true)
      end
    end

    context "with invalid params" do
      let(:params) { { email: "invalid" } }

      it "raises error" do
        expect { repo.update!(account.id, params) }.to raise_error described_class::Error
      end
    end
  end

  describe "#create!" do
    let(:from_lead_attributes) { %w[campaign terms id created_at] }
    let(:customer) { create(:customer, :prospect) }

    it "creates a new customer" do
      account = repo.create!(customer.id, "example@clark.de", "Test1234")
      expect(account).to be_kind_of Customer::Constituents::Account::Entities::Account

      user = User.find_by!(mandate_id: customer.id)
      expect(account.id).to eq user.id
      expect(account.email).to eq "example@clark.de"
      expect(user.source_data["from_lead"].keys).to match_array(from_lead_attributes)
    end

    it "validates data on AR side" do
      expect { repo.create!(customer.id, "example", "Test1234") }.to raise_error described_class::Error
      expect { repo.create!(customer.id, "example@clark.de", "qwerty") }.to raise_error described_class::Error
    end

    it "downcase provided email before saving" do
      account = repo.create!(customer.id, "example@clark.dE", "Test1234")

      expect(account.email).to eq "example@clark.de"
    end
  end

  describe "#generate_reset_password_token" do
    it "generates a reset_password_token for the user" do
      user = create(:user, :with_mandate)

      Timecop.freeze(Date.today) do
        raw_token = repo.generate_reset_password_token(user.email)
        expect(raw_token).not_to be_nil

        retrieved_user = User.with_reset_password_token(raw_token)
        expect(retrieved_user.id).to eql(user.id)
        expect(retrieved_user.reset_password_sent_at).to eql(Time.zone.now)
      end
    end

    it "can handle case-insensitive email" do
      user = create(:user, :with_mandate, email: "foo@bar.com")
      raw_token = repo.generate_reset_password_token("foO@bAr.coM")
      expect(raw_token).not_to be_nil

      expect(User.with_reset_password_token(raw_token).id).to eql(user.id)
    end

    it "returns no token if no user is found" do
      raw_token = repo.generate_reset_password_token("invalid-email@invalid.xx")
      expect(raw_token).to be_nil
    end
  end

  describe "#clear_reset_password_token!" do
    context "with existent token" do
      it "clears token and sent_at" do
        user = create(:user, :with_mandate)
        raw_token = user.send(:set_reset_password_token)
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_present

        repo.clear_reset_password_token!(raw_token)

        user.reload
        expect(user.reset_password_token).to be_nil
        expect(user.reset_password_sent_at).to be_nil
      end
    end

    context "with unknown token" do
      it "does nothing" do
        expect { repo.clear_reset_password_token!("unknown-token") }.not_to raise_error
      end
    end
  end
end
