# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Referrals::Campaigns do
  describe "#get_invitees_with_two_or_more_products" do
    let(:user_1) { create :user, :with_mandate, :direkt_1822 }
    let(:user_2) { create :user, :with_mandate, :direkt_1822 }
    let!(:product1) { create(:product, :details_available, mandate: user_1.mandate) }
    let!(:product2) { create(:product, :details_available, mandate: user_1.mandate) }
    let!(:product3) { create(:product, :details_available, mandate: user_2.mandate) }

    it "doesn't return the correct mandate with 2 or more valid products if no excluded category and no invitee" do
      user_1.mandate.update!(state: :accepted)
      user_2.mandate.update!(state: :accepted)
      result = described_class.get_invitees_with_two_or_more_products("1822direkt")
      expect(result[0]).to be_nil
      expect(result[1]).to be_nil
    end

    it "returns the correct mandate with 2 or more valid products if no excluded category and is invitee" do
      user_1.mandate.update!(state: :accepted)
      user_1.inviter_id = user_2.id
      user_1.save!
      user_2.mandate.update!(state: :accepted)
      result = described_class.get_invitees_with_two_or_more_products("1822direkt")
      expect(result[0]).to eq(user_1.mandate)
      expect(result[1]).to be_nil
    end

    context "returns mandate based on a date if specified" do
      before do
        user_1.mandate.update!(state: :accepted)
        user_1.mandate.update!(created_at: Time.zone.now - 90.days)
        user_1.inviter_id = user_2.id
        user_1.save!
        user_2.mandate.update!(state: :accepted)
      end

      it "returns if mandate created after the date specified" do
        result = described_class
                 .get_invitees_with_two_or_more_products("1822direkt",
                                                         created_at_low_bound: (Time.zone.now - 85.days))
        expect(result[0]).to be_nil
        expect(result[1]).to be_nil
      end

      it "doesn't return if mandate created after the date specified" do
        result = described_class
                 .get_invitees_with_two_or_more_products("1822direkt",
                                                         created_at_low_bound: (Time.zone.now - 95.days))
        expect(result[0]).to eq(user_1.mandate)
        expect(result[1]).to be_nil
      end
    end

    context "with excluded categories idents" do
      before do
        allow(Domain::MasterData::Categories).to receive(:get_by_ident).and_return(product1.plan.category,
                                                                                   product2.plan.category,
                                                                                   product3.plan.category)
      end

      it "filters the mandate with a product of category excluded" do
        user_1.mandate.update!(state: :accepted)
        user_2.mandate.update!(state: :accepted)
        result = described_class
                 .get_invitees_with_two_or_more_products("1822direkt", excluded_categories: [product1.plan.category_ident])
        expect(result[0]).to be_nil
      end
    end

    context "with mandate not accepted" do
      before do
        allow(Domain::MasterData::Categories).to receive(:get_by_ident).and_return(product1.plan.category,
                                                                                   product2.plan.category,
                                                                                   product3.plan.category)
      end

      it "filters the mandates which are not accepted" do
        result = described_class
                 .get_invitees_with_two_or_more_products("1822direkt", excluded_categories: [product1.plan.category_ident])
        expect(result[0]).to be_nil
      end
    end
  end

  describe "#mark_inviters_payed_for_invitees" do
    let(:create_mandate) do
      lambda do |inviter=nil|
        create(:mandate, :accepted, user: create(:user, inviter_id: inviter&.id), iban: "DE56048290290409243959")
      end
    end

    let(:accepted_inviter) { create_mandate.() }

    let(:invitee_enough_products) { create_mandate.(accepted_inviter.user) }

    let(:allowed_category) { create(:category_phv) }

    let(:min_count_products) { Domain::Referrals::InviteeProductFilter::MIN_PRODUCTS_COUNT }

    let(:allowed_plan) { create(:plan, category: allowed_category) }

    let(:standard_product_state) { "details_available" }

    let(:forbidden_category_ident) { "forbidden" }
    let(:forbidden_category) { create(:category, ident: forbidden_category_ident) }
    let(:forbidden_plan) { create(:plan, category: forbidden_category) }

    context "when inviters exists with invitees for which they are not payed for yet" do
      let!(:repository) do
        Domain::Referrals::InviterRepository
          .new(excluded_category_idents: [forbidden_category_ident])
      end

      before do
        attach_product = lambda do |invitee, state=nil|
          invitee.products << create(:product, plan: allowed_plan, state: state || standard_product_state)
        end

        # matching:
        min_count_products.times { attach_product.(invitee_enough_products) }
      end

      it "marks the invitees to be paid out if inviter has iban" do
        result = repository.invitations_with_outstanding_payments
        expect(result).not_to be_empty
        described_class.mark_inviters_payed_for_invitees(result, Time.zone.now)
        result = repository.invitations_with_outstanding_payments
        expect(result).to be_empty
      end

      it "marks the invitees not paid out if inviter does not have iban" do
        accepted_inviter.update(iban: nil)
        result = repository.invitations_with_outstanding_payments
        described_class.mark_inviters_payed_for_invitees(result, Time.zone.now)
        result = repository.invitations_with_outstanding_payments
        expect(result).not_to be_empty
      end

      it "has all invitees updated to be marked as payout" do
        result = repository.invitations_with_outstanding_payments
        expect(invitee_enough_products.user.paid_inviter_at).to be_nil
        described_class.mark_inviters_payed_for_invitees(result, Time.zone.now)
        expect(invitee_enough_products.reload.user.paid_inviter_at).not_to be_nil
      end
    end
  end
end
