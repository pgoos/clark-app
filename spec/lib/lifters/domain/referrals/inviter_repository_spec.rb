# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Referrals::InviterRepository, :integration do
  subject { described_class.new(excluded_category_idents: [forbidden_category_ident]) }

  let(:create_mandate) do
    lambda do |inviter=nil|
      if inviter.blank?
        create(:mandate, :accepted, user: create(:user))
      else
        create(:mandate, :accepted, user: create(:user, inviter_id: inviter.id))
      end
    end
  end

  let(:accepted_inviter_1) { create_mandate.() }
  let(:accepted_inviter_2) { create_mandate.() }
  let(:accepted_inviter_3) { create_mandate.() }

  let(:revoked_inviter) { create(:mandate, :revoked, user: create(:user)) }
  let(:created_inviter) { create(:mandate, :created, user: create(:user)) }

  let(:invitee_not_enough_products_1) { create_mandate.(accepted_inviter_1.user) }
  let(:invitee_not_enough_products_2) { create_mandate.(accepted_inviter_3.user) }
  let(:invitee_enough_products_1) { create_mandate.(accepted_inviter_1.user) }
  let(:invitee_enough_products_2) { create_mandate.(accepted_inviter_2.user) }
  let(:invitee_products_with_varying_states_1) { create_mandate.(accepted_inviter_2.user) }
  let(:invitee_products_with_varying_states_2) { create_mandate.(accepted_inviter_2.user) }
  let(:invitee_products_with_wrong_states) { create_mandate.(accepted_inviter_2.user) }
  let(:invitee_products_wrong_category) { create_mandate.(accepted_inviter_2.user) }
  let(:invitee_from_revoked) { create_mandate.(revoked_inviter.user) }
  let(:invitee_from_created) { create_mandate.(created_inviter.user) }

  let(:to_be_included_inviter_mappings) do
    {
      accepted_inviter_1.user => [
        invitee_enough_products_1.user
      ],
      accepted_inviter_2.user => [
        invitee_enough_products_2.user,
        invitee_products_with_varying_states_1.user,
        invitee_products_with_varying_states_2.user
      ]
    }
  end

  let(:allowed_product_states) { described_class::ACCEPTED_PRODUCT_STATES }
  let(:forbidden_product_states) { Product.state_machine.states.keys.map(&:to_s) - allowed_product_states }
  let(:standard_product_state) { "details_available" }
  let(:allowed_category) { create(:category_phv) }
  let(:allowed_plan) { create(:plan, category: allowed_category) }

  let(:forbidden_category_ident) { "forbidden" }
  let(:forbidden_category) { create(:category, ident: forbidden_category_ident) }
  let(:forbidden_plan) { create(:plan, category: forbidden_category) }

  let(:min_count_products) { 2 }

  it "should only find inviters -> *invitees, if in allowed states and with according products" do
    attach_product = lambda do |invitee, state=nil|
      invitee.products << create(:product, plan: allowed_plan, state: state || standard_product_state)
    end

    # matching:
    min_count_products.times { attach_product.(invitee_enough_products_1) }
    min_count_products.times { attach_product.(invitee_enough_products_2) }

    allowed_product_states[0..2].each { |state| attach_product.(invitee_products_with_varying_states_1, state) }
    allowed_product_states[2..4].each { |state| attach_product.(invitee_products_with_varying_states_2, state) }

    # not matching:
    too_few = (min_count_products - 1)

    # too few:
    too_few.times { attach_product.(invitee_not_enough_products_1) }

    # wrong product states:
    too_few.times { attach_product.(invitee_products_with_wrong_states) }
    forbidden_product_states.each { |state| attach_product.(invitee_products_with_wrong_states, state) }

    # inviter revoked:
    min_count_products.times { attach_product.(invitee_from_revoked) }

    # inviter not yet accepted:
    min_count_products.times { attach_product.(invitee_from_created) }

    # invitee not enough products of accepted categories:
    too_few.times { attach_product.(invitee_products_wrong_category) }
    invitee_products_wrong_category.products << create(:product, plan: forbidden_plan, state: standard_product_state)

    # accepted mandate not inviter:
    create(:mandate, :accepted, user: create(:user))

    result = subject.invitations_with_outstanding_payments
    inviters = result.map { |tuple| tuple[0] }

    expect(inviters).to contain_exactly(*to_be_included_inviter_mappings.keys)

    matching_invitees1 = to_be_included_inviter_mappings[accepted_inviter_1.user]
    expect(result[accepted_inviter_1.user]).to contain_exactly(*matching_invitees1)

    matching_invitees2 = to_be_included_inviter_mappings[accepted_inviter_2.user]
    expect(result[accepted_inviter_2.user]).to contain_exactly(*matching_invitees2)

    expect(result.values.select(&:empty?)).to be_empty
  end

  context "when an elligible invitee exists but is linked to self" do
    let(:self_invited_mandate) { create(:mandate, :accepted, user: create(:user)) }

    before do
      self_invited_mandate.user.inviter_id = self_invited_mandate.user.id
      self_invited_mandate.user.save!

      invitee_enough_products_1.user.inviter_id = nil
      invitee_enough_products_1.user.save!

      attach_product = lambda do |invitee, state=nil|
        invitee.products << create(:product, plan: allowed_plan, state: state || standard_product_state)
      end
      min_count_products.times { attach_product.(self_invited_mandate) }
      min_count_products.times { attach_product.(invitee_enough_products_1) }
    end

    it "returns empty since invitee is linked to self" do
      result = subject.referral_participants_to_pay
      inviters = result.map { |tuple| tuple[0] }
      expect(inviters).to be_empty
    end

    context "when additional to self invitee a valid invitee exists" do
      let(:expected_result) do
        {
          self_invited_mandate.user => [
            invitee_enough_products_1.user
          ]
        }
      end

      before do
        invitee_enough_products_1.user.inviter_id = self_invited_mandate.user.id
        invitee_enough_products_1.user.save!
        invitee_enough_products_1.created_at = 1.month.ago
        invitee_enough_products_1.save!
      end

      it "only includes the valid invitee and not the self" do
        result = subject.referral_participants_to_pay
        expect(result).to eq(expected_result)
      end
    end
  end

  context "when filtering the inviter based on invitees" do
    context "when invitee created less that a year ago and has two accepted products" do
      before do
        invitee_enough_products_1.created_at = 1.month.ago
      end

      context "when the invitee has two accepted products" do
        let(:expected_result) do
          {
            accepted_inviter_1.user => [
              invitee_enough_products_1.user
            ]
          }
        end

        before do
          attach_product = lambda do |invitee, state=nil|
            invitee.products << create(:product, plan: allowed_plan, state: state || standard_product_state)
          end
          invitee_enough_products_2.user.inviter_id = nil
          invitee_enough_products_2.user.save!
          min_count_products.times { attach_product.(invitee_enough_products_1) }
          min_count_products.times { attach_product.(invitee_enough_products_2) }
        end

        it "returns the invitees with 2 accepted products and accepted mandate less than a year" do
          result = subject.referral_participants_to_pay
          inviters = result.map { |tuple| tuple[0] }
          expect(inviters).to contain_exactly(*expected_result.keys)
        end

        context "when one of the invitee is not in accpeted state" do
          let(:expected_result_with_valid_invitee) do
            {
              accepted_inviter_1.user => [
                invitee_enough_products_2.user
              ]
            }
          end

          before do
            invitee_enough_products_1.state = "revoked"
            invitee_enough_products_1.save!
          end

          it "does not include the inviter since the invitee is in invalid state" do
            result = subject.referral_participants_to_pay
            expect(result).to be_empty
          end

          it "includes only the invitee of correct state" do
            invitee_enough_products_2.user.inviter_id = accepted_inviter_1.user.id
            invitee_enough_products_2.user.save!
            invitee_enough_products_2.state = "accepted"
            result = subject.referral_participants_to_pay
            expect(result).to eq(expected_result_with_valid_invitee)
          end
        end
      end

      context "when the invitee has NOT two accepted products" do
        it "returns the invitees with 2 accepted products and accepted mandate less than a year" do
          result = subject.referral_participants_to_pay
          inviters = result.map { |tuple| tuple[0] }
          expect(inviters).to be_empty
        end
      end
    end

    context "when invitee created more that a year ago and has two accepted products" do
      before do
        attach_product = lambda do |invitee, state=nil|
          invitee.products << create(:product, plan: allowed_plan, state: state || standard_product_state)
        end
        min_count_products.times { attach_product.(invitee_enough_products_1) }
      end

      it "returns the invitees with 2 accepted products and accepted mandate less than a year" do
        invitee_enough_products_1.update(created_at: 2.years.ago)
        result = subject.referral_participants_to_pay
        inviters = result.map { |tuple| tuple[0] }
        expect(inviters).to be_empty
      end
    end
  end
end
