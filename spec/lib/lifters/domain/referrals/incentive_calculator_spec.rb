# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Referrals::IncentiveCalculator do
  subject { described_class.new(invitees: invitees, excluded_categories: [excluded_category_ident]) }

  let(:zero) { Monetize.parse("0 €") }
  let(:inviter_incentive) { Monetize.parse("75 €") }
  let(:invitee_payout_minimum) { Monetize.parse("30 €") }
  let(:invitee_payout_delta) { Monetize.parse("15 €") }
  let(:invitee_payout_maximum) { Monetize.parse("150 €") }

  let(:inviter) { instance_double(User, mandate: mandate) }

  let(:mandate) { instance_double(Mandate) }

  let(:invitees) { [invitee1] }

  let(:invitee1) { instance_double(User, mandate: mandate1, paid_inviter_at: nil) }
  let(:mandate1) { instance_double(Mandate, products: products1) }
  let(:products1) { [new_product.()] }

  let(:invitee2) { instance_double(User, mandate: mandate2, paid_inviter_at: nil) }
  let(:mandate2) { instance_double(Mandate, products: products2) }
  let(:products2) { [new_product.()] }

  let(:valid_category_ident) { Category.phv_ident }
  let(:excluded_category_ident) { "excluded_category_ident" }
  let(:valid_state) { "details_available" }
  let(:excluded_states) { Product.state_machine.states.keys.map(&:to_s) - described_class::ACCEPTED_PRODUCT_STATES }
  let(:new_product) do
    lambda do |category_ident=valid_category_ident, state=valid_state|
      instance_double(Product, category_ident: category_ident, state: state)
    end
  end

  before do
    settings = OpenStruct.new(
      inviter_payout:  "75 €",
      invitee_payout: OpenStruct.new(
        minimum: "30 €",
        delta:   "15 €",
        maximum: "150 €"
      )
    )
    allow(Settings).to receive(:incentives).and_return(settings)
  end

  describe "#inviter_incentive" do
    it "should be 0 if the invitee has less than 2 products" do
      expect(subject.inviter_incentive).to eq(zero)
    end

    it "should be 1 x inviter incentive, if the invitee has at least 2 valid products" do
      products1 << new_product.()
      expect(subject.inviter_incentive).to eq(inviter_incentive)
    end

    it "should be 0 if the invitee has not enough valid products" do
      products1 << new_product.(excluded_category_ident)
      expect(subject.inviter_incentive).to eq(zero)
    end

    it "should be 0, if the invitee has at least 2 valid products but was already paid" do
      products1 << new_product.()
      allow(invitee1).to receive(:paid_inviter_at).and_return(1.second.ago)
      expect(subject.inviter_incentive).to eq(zero)
    end

    it "should be 2 x inviter incentive, if there are two valid invitees" do
      products1 << new_product.()
      products2 << new_product.()
      invitees << invitee2
      expect(subject.inviter_incentive).to eq(inviter_incentive * 2)
    end

    it "should be 1 x inviter incentive, if there are more than one invitees but only one valid" do
      products1 << new_product.()
      products2 << new_product.()
      products3 = [new_product.(), new_product.(excluded_category_ident)]
      mandate3 = instance_double(Mandate, products: products3)
      invitee3 = instance_double(User, mandate: mandate3, paid_inviter_at: nil)
      invitees << invitee2 << invitee3
      allow(invitee2).to receive(:paid_inviter_at).and_return(1.second.ago)

      expect(subject.inviter_incentive).to eq(inviter_incentive)
    end
  end

  describe "#gained_customer_incentives" do
    let(:maximum_amount) { ((invitee_payout_maximum - invitee_payout_minimum) / invitee_payout_delta).to_i + 2 }

    it "should receive zero, if there are not enough products" do
      invitee_incentives = subject.gained_customer_incentives
      expect(invitee_incentives[invitee1]).to eq(zero)
    end

    it "should receive the invitee minimum, if there are 2 valid products" do
      products1 << new_product.()
      invitee_incentives = subject.gained_customer_incentives
      expect(invitee_incentives[invitee1]).to eq(invitee_payout_minimum)
    end

    it "should receive zero, if there is just one valid product among others" do
      products1 << new_product.(excluded_category_ident)
      excluded_states.each do |state|
        products1 << new_product.(valid_category_ident, state)
      end

      invitee_incentives = subject.gained_customer_incentives
      expect(invitee_incentives[invitee1]).to eq(zero)
    end

    it "should receive the invitee minimum + delta, if there are 3 valid products" do
      2.times { products1 << new_product.() }
      invitee_incentives = subject.gained_customer_incentives
      expect(invitee_incentives[invitee1]).to eq(invitee_payout_minimum + invitee_payout_delta)
    end

    it "should receive the invitee maximum, if the maximum count of products is reached" do
      maximum_amount.times { products1 << new_product.() }
      invitee_incentives = subject.gained_customer_incentives
      expect(invitee_incentives[invitee1]).to eq(invitee_payout_maximum)
    end

    it "should receive the invitee maximum, if there are more products than the maximum count of products" do
      (maximum_amount + 1).times { products1 << new_product.() }
      invitee_incentives = subject.gained_customer_incentives
      expect(invitee_incentives[invitee1]).to eq(invitee_payout_maximum)
    end

    it "should calculate the incentives for all given invitees" do
      products1 << new_product.()
      products2 << new_product.()
      invitees << invitee2

      invitee_incentives = subject.gained_customer_incentives
      expect(invitee_incentives[invitee2]).to eq(invitee_payout_minimum)
    end
  end
end
