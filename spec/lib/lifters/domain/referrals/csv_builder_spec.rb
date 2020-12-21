# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Referrals::CsvBuilder do
  let(:subject) { described_class }

  let(:create_mandate) do
    lambda do |inviter=nil|
      create(
        :mandate,
        :accepted,
        first_name: "Őriző",
        last_name: "Müller",
        user: create(:user, inviter_id: inviter&.id)
      )
    end
  end

  let(:accepted_inviter_1) { create_mandate.() }
  let(:accepted_inviter_2) { create_mandate.() }

  let(:invitee_enough_products_1) { create_mandate.(accepted_inviter_1.user) }
  let(:invitee_enough_products_2) { create_mandate.(accepted_inviter_2.user) }

  let(:allowed_category) { create(:category_phv) }

  let(:min_count_products) { 2 }

  let(:allowed_plan) { create(:plan, category: allowed_category) }

  let(:standard_product_state) { "details_available" }

  let(:forbidden_category_ident) { "forbidden" }
  let(:forbidden_category) { create(:category, ident: forbidden_category_ident) }
  let(:forbidden_plan) { create(:plan, category: forbidden_category) }

  describe "#create_csv" do
    let!(:repository) { Domain::Referrals::InviterRepository.new(excluded_category_idents: [forbidden_category_ident]) }

    context "when invitee satify condition" do
      before do
        attach_product = lambda do |invitee, state=nil|
          invitee.products << create(:product, plan: allowed_plan, state: state || standard_product_state)
        end

        # matching:
        min_count_products.times { attach_product.(invitee_enough_products_1) }
        min_count_products.times { attach_product.(invitee_enough_products_2) }
      end

      it "returns the expected csv with proper result" do
        expected_csv = <<~CSV
          Mandate ID (inviter),First name (inviter),Last name (inviter),IBAN (inviter),BIC (inviter),Amount (inviter),Mandate ID (invitee),Mandate state (invitee),First name (invitee),Last name (invitee),Mandate created at (invitee),Mandate confirming date (invitee),Mandate accepted date (invitee)
          #{accepted_inviter_2.id},#{accepted_inviter_2.first_name},#{accepted_inviter_2.last_name},,,\"\",#{invitee_enough_products_2.id},#{invitee_enough_products_2.state&.to_s&.humanize},#{invitee_enough_products_2.first_name},#{invitee_enough_products_2.last_name},#{invitee_enough_products_2.created_at.strftime('%Y-%m-%d')},,#{invitee_enough_products_2.tos_accepted_at.strftime('%Y-%m-%d')}
          #{accepted_inviter_1.id},#{accepted_inviter_1.first_name},#{accepted_inviter_1.last_name},,,\"\",#{invitee_enough_products_1.id},#{invitee_enough_products_1.state&.to_s&.humanize},#{invitee_enough_products_1.first_name},#{invitee_enough_products_1.last_name},#{invitee_enough_products_1.created_at.strftime('%Y-%m-%d')},,#{invitee_enough_products_1.tos_accepted_at.strftime('%Y-%m-%d')}
        CSV

        accepted_inviter_2.iban = "DE89370400440532013000"
        accepted_inviter_1.iban = "DE89370400440532013000"
        accepted_inviter_2.save!
        accepted_inviter_1.save!
        result = repository.invitations_with_outstanding_payments
        csv = subject.create_csv(result, forbidden_category_ident)

        # expect(csv).to eq(expected_csv)
        expect(csv.lines.count).to eq(3)
      end

      it "returns the expected csv if one of the inviter is paid for one of invitee" do
        expected_csv = <<~CSV
          Mandate ID (inviter),First name (inviter),Last name (inviter),IBAN (inviter),BIC (inviter),Amount (inviter),Mandate ID (invitee),Mandate state (invitee),First name (invitee),Last name (invitee),Mandate created at (invitee),Mandate confirming date (invitee),Mandate accepted date (invitee)
          #{accepted_inviter_2.id},#{accepted_inviter_2.first_name},#{accepted_inviter_2.last_name},,,\"\",#{invitee_enough_products_2.id},#{invitee_enough_products_2.state&.to_s&.humanize},#{invitee_enough_products_2.first_name},#{invitee_enough_products_2.last_name},#{invitee_enough_products_2.created_at.strftime('%Y-%m-%d')},,#{invitee_enough_products_2.tos_accepted_at.strftime('%Y-%m-%d')}
          #{accepted_inviter_1.id},#{accepted_inviter_1.first_name},#{accepted_inviter_1.last_name},,,\"\",#{invitee_enough_products_1.id},#{invitee_enough_products_1.state&.to_s&.humanize},#{invitee_enough_products_1.first_name},#{invitee_enough_products_1.last_name},#{invitee_enough_products_1.created_at.strftime('%Y-%m-%d')},,#{invitee_enough_products_1.tos_accepted_at.strftime('%Y-%m-%d')}
        CSV
        accepted_inviter_2.iban = "DE89370400440532013000"
        accepted_inviter_1.iban = "DE89370400440532013000"
        accepted_inviter_2.save!
        accepted_inviter_1.save!

        invitee_enough_products_2.user.paid_inviter_at = Time.zone.now
        invitee_enough_products_2.user.save!
        result = repository.invitations_with_outstanding_payments
        csv = subject.create_csv(result, forbidden_category_ident)

        # expect(csv).to eq(expected_csv)
        expect(csv.lines.count).to eq(2)
      end

      it "does not show the inviters to pay whom does not have an iban" do
        expected_csv = <<~CSV
          Mandate ID (inviter),First name (inviter),Last name (inviter),IBAN (inviter),BIC (inviter),Amount (inviter),Mandate ID (invitee),Mandate state (invitee),First name (invitee),Last name (invitee),Mandate created at (invitee),Mandate confirming date (invitee),Mandate accepted date (invitee)
          #{accepted_inviter_1.id},#{accepted_inviter_1.first_name},#{accepted_inviter_1.last_name},,,\"\",#{invitee_enough_products_1.id},#{invitee_enough_products_1.state&.to_s&.humanize},#{invitee_enough_products_1.first_name},#{invitee_enough_products_1.last_name},#{invitee_enough_products_1.created_at.strftime('%Y-%m-%d')},,#{invitee_enough_products_1.tos_accepted_at.strftime('%Y-%m-%d')}
        CSV

        accepted_inviter_1.iban = "DE89370400440532013000"
        accepted_inviter_2.save!
        accepted_inviter_1.save!
        result = repository.invitations_with_outstanding_payments
        csv = subject.create_csv(result, forbidden_category_ident)

        # expect(csv).to eq(expected_csv)
        expect(csv.lines.count).to eq(2)
      end
    end

    context "when invitee do not satisfy the condition" do
      it "returns an empty csv" do
        expected_csv = <<~CSV
          Mandate ID (inviter),First name (inviter),Last name (inviter),IBAN (inviter),BIC (inviter),Amount (inviter),Mandate ID (invitee),Mandate state (invitee),First name (invitee),Last name (invitee),Mandate created at (invitee),Mandate confirming date (invitee),Mandate accepted date (invitee)
        CSV
        result = repository.invitations_with_outstanding_payments
        csv = subject.create_csv(result, forbidden_category_ident)

        # expect(csv).to eq(expected_csv)
        expect(csv.lines.count).to eq(1)
      end
    end
  end
end
