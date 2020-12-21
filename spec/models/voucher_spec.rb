# frozen_string_literal: true

# == Schema Information
#
# Table name: vouchers
#
#  id          :integer          not null, primary key
#  name        :string
#  code        :string
#  amount      :integer
#  valid_from  :datetime
#  valid_until :datetime
#  metadata    :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require "rails_helper"

RSpec.describe Voucher, type: :model do
  # Setup
  let!(:subject) { FactoryBot.build(:voucher) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  it_behaves_like "an auditable model"

  # State Machine
  # Scopes
  # Associations
  it { expect(subject).to have_many(:mandates).dependent(:restrict_with_error) }

  # Nested Attributes
  # Validations
  it { expect(subject).to validate_presence_of(:valid_from) }
  it { expect(subject).to validate_presence_of(:valid_until) }
  it { expect(subject).to validate_presence_of(:name) }
  it { expect(subject).to validate_presence_of(:source) }
  it { expect(subject).to validate_presence_of(:campaign) }

  # Callbacks
  context "#generate_and_sanitize_code" do
    it "generates a code if there is none before validation" do
      subject.code = nil

      expect { subject.run_callbacks(:validation) }
        .to change(subject, :code).from(nil)
    end

    it "does not generate code if one is set" do
      subject.code = "SOME-CODE"

      expect { subject.run_callbacks(:validation) }
        .not_to change(subject, :code)
    end

    it "upcases the code" do
      subject.code = "test123"

      expect { subject.run_callbacks(:validation) }
        .to change(subject, :code).from("test123").to("TEST123")
    end

    it "strips spaces from the code" do
      subject.code = " TEST-FOO\t\n"

      expect { subject.run_callbacks(:validation) }
        .to change(subject, :code).to("TEST-FOO")
    end
  end

  # Instance Methods
  context "#redeemable?" do
    it "returns false if voucher is not yet valid" do
      expect(Voucher.new(valid_from: 1.day.from_now)).not_to be_redeemable
    end

    it "returns false if voucher is expired" do
      expect(Voucher.new(valid_from: 3.days.ago, valid_until: 1.day.ago)).not_to be_redeemable
    end

    it "returns false if voucher is used up" do
      voucher = Voucher.new(valid_from: 3.days.ago, valid_until: 1.day.from_now)
      expect(voucher).to receive(:available_amount).and_return(0)
      expect(voucher).not_to be_redeemable
    end

    it "returns true otherwise" do
      voucher = Voucher.new(valid_from: 3.days.ago, valid_until: 1.day.from_now)
      expect(voucher).to receive(:available_amount).and_return(7)
      expect(voucher).to be_redeemable
    end
  end

  # Class Methods

  context ".redeem_for", :integration do
    let(:voucher)       { create(:voucher) }
    let(:mandate)       { create(:mandate) }
    let!(:user)         { create(:user, mandate: mandate) }
    let(:error_message) { I18n.t("activerecord.errors.models.mandate.attributes.voucher_code.invalid") }

    before { Timecop.freeze(Time.zone.now) }

    after { Timecop.return }

    it "attaches the voucher to the mandate" do
      mandate.voucher_code = voucher.code

      expect { Voucher.redeem_for(mandate) }
        .to change(mandate, :voucher_id).from(nil).to(voucher.id)

      expect(mandate.errors[:voucher_code].first).to be_nil
    end

    it "adds added_at and redeemed_at te mandate info" do
      mandate.voucher_code = voucher.code

      Voucher.redeem_for(mandate)

      expect(mandate.info["voucher"]["added_at"]).to eq(Time.now.to_i)
      expect(mandate.info["voucher"]["redeemed_at"]).to eq(Time.now.to_i)
    end

    it "does not add an error when the voucher is already attached to the mandate" do
      # Limit the voucher to 1 usage so it would raise an error
      voucher.update_attributes(amount: 1)
      mandate.update(voucher: voucher)
      mandate.voucher_code = voucher.code

      expect { Voucher.redeem_for(mandate) }
        .not_to change(mandate, :voucher_id)

      expect(mandate.errors[:voucher_code].first).to be_nil
    end

    it "attaches the voucher to the mandate regardless of case" do
      mandate.voucher_code = voucher.code.downcase

      expect {Voucher.redeem_for(mandate)}
        .to change(mandate, :voucher_id).from(nil).to(voucher.id)

      expect(mandate.errors[:voucher_code].first).to be_nil
    end

    it "adds an error to the mandate when the voucher can not be found" do
      mandate.voucher_code = "some-not-existing-code"

      expect { Voucher.redeem_for(mandate) }
        .not_to change(mandate, :voucher_id)

      expect(mandate.errors[:voucher_code].first.include?("ist nicht (mehr) gültig"))
        .to be_truthy
    end

    it "adds an error to the mandate when the voucher is not redeemable" do
      allow_any_instance_of(Voucher).to receive(:redeemable?).and_return(false)
      mandate.voucher_code = voucher.code

      expect { Voucher.redeem_for(mandate) }
        .not_to change(mandate, :voucher_id)

      expect(mandate.errors[:voucher_code].first.include?("ist nicht (mehr) gültig"))
        .to be_truthy
    end
  end
end
