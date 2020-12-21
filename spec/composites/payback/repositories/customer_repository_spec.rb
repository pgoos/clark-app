# frozen_string_literal: true

require "rails_helper"
require "composites/payback/repositories/customer_repository"

RSpec.describe Payback::Repositories::CustomerRepository do
  subject(:repository) { described_class.new }

  let(:payback_mandate) { create(:mandate, :payback) }
  let(:valid_payback_number) { "3083423833292681" }

  describe "#find" do
    let(:mandate) {
      create(
        :mandate,
        :payback_with_data,
        :in_rewardable_payback_period,
        state: "in_creation"
      )
    }

    it "returns entity with aggregated data" do
      customer = repository.find(mandate.id)

      expect(customer).to be_kind_of Payback::Entities::Customer

      expect(customer.id).to eq(mandate.id)
      expect(customer.mandate_state).to eq "in_creation"
      expect(customer.payback_enabled).to be_truthy
      expect(customer.payback_data).to eq(mandate.loyalty["payback"])
      expect(customer.payback_number).to be_truthy
      expect(customer.in_rewardable_period?).to be_truthy
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repository.find(9999)).to be_nil
      end
    end

    context "when customer is outside of eligibility period" do
      let(:ineligible_mandate) {
        create(
          :mandate,
          :payback_with_data,
          :outside_rewardable_payback_period
        )
      }

      it "responds to the be_in_rewardable_period method with false" do
        customer = repository.find(ineligible_mandate.id)
        expect(customer.in_rewardable_period?).to be_falsey
      end
    end

    context "when customer has not been accepted" do
      let(:not_accepted_mandate) {
        create(
          :mandate,
          :payback_with_data
        )
      }

      it "responds to the in_eligible_period? method with false" do
        customer = repository.find(not_accepted_mandate.id)
        expect(customer.in_rewardable_period?).to be_falsey
      end
    end
  end

  describe "#enable_payback" do
    let(:mandate) {
      create(
        :mandate,
        lead: create(:lead),
        state: "in_creation"
      )
    }

    it "enables payback source and returns entity" do
      customer = repository.enable_payback(mandate.id)

      expect(customer).to be_kind_of Payback::Entities::Customer
      expect(customer.payback_enabled).to be_truthy
    end
  end

  describe "#update_payback_number" do
    it "updates payback number and returns entity aggregated data" do
      expected_payback_data = {
        "rewardedPoints" => {
          "locked" => 0,
          "unlocked" => 0
        },
        "paybackNumber" => valid_payback_number
      }

      customer = repository.update_payback_number(payback_mandate.id, valid_payback_number)

      expect(customer).to be_kind_of Payback::Entities::Customer
      expect(customer.payback_enabled).to be_truthy
      expect(customer.payback_data).to eq(expected_payback_data)
    end
  end

  describe "#save_api_authentication_failure" do
    let(:customer) {
      create(
        :mandate,
        :payback_with_data,
        state: "accepted"
      )
    }

    it "saves the fail with the key authentication_failed under loylaty/payback data" do
      repository.save_api_authentication_failure(customer.id)

      expect(customer.reload.loyalty["payback"]["authenticationFailed"]).to be_truthy
    end
  end

  describe "#add_locked_points" do
    let(:mandate) {
      create(
        :mandate,
        :payback_with_data,
        state: "in_creation",
        loyalty: {
          payback: {
            "rewardedPoints" => {
              "locked" => 20,
              "unlocked" => 0
            }
          }
        }
      )
    }

    it "updates payback locked points amount and returns entity aggregated data" do
      expected_payback_points_data = {
        "locked" => 35,
        "unlocked" => 0
      }

      customer = repository.add_locked_points(mandate.id, 15)

      expect(customer).to be_kind_of Payback::Entities::Customer
      expect(customer.payback_data["rewardedPoints"]).to eq(expected_payback_points_data)
    end
  end

  describe "#subtract_locked_points" do
    let(:mandate) {
      create(
        :mandate,
        :payback_with_data,
        state: "in_creation",
        loyalty: {
          payback: {
            "rewardedPoints" => {
              "locked" => 20,
              "unlocked" => 0
            }
          }
        }
      )
    }

    it "updates payback locked points amount and returns entity aggregated data" do
      expected_payback_points_data = {
        "locked" => 5,
        "unlocked" => 0
      }

      customer = repository.subtract_locked_points(mandate.id, 15)

      expect(customer).to be_kind_of Payback::Entities::Customer
      expect(customer.payback_data["rewardedPoints"]).to eq(expected_payback_points_data)
    end
  end

  describe "#payback_number_unique?" do
    context "when mandate with that number exists" do
      it "returns false" do
        create(
          :mandate,
          :payback_with_data,
          paybackNumber: valid_payback_number,
          state: "accepted"
        )

        mandate = create(
          :mandate,
          :payback
        )

        expect(repository.payback_number_unique?(mandate.id, valid_payback_number)).to be_falsy
      end
    end

    context "when there is not existing mandate with that number" do
      it "return true" do
        expect(repository.payback_number_unique?(payback_mandate.id, valid_payback_number)).to be_truthy
      end
    end
  end

  describe "#unlock_points" do
    let(:locked_points) { 750 }
    let(:mandate) {
      create(
        :mandate,
        :payback_with_data,
        loyalty: {
          payback: {
            "paybackNumber" => valid_payback_number,
            "rewardedPoints" => {
              "locked" => locked_points,
              "unlocked" => 0
            }
          }
        }
      )
    }

    let(:expected_points) { { "locked" => 0, "unlocked" => locked_points } }

    it "updates payback rewarded points and returns entity aggregated data" do
      customer = repository.unlock_points(mandate.id, locked_points)

      expect(customer).to be_kind_of Payback::Entities::Customer
      expect(customer.payback_data["rewardedPoints"]).to eq(expected_points)
    end
  end

  describe "#recalculate_points" do
    let(:mandate) { create(:mandate, :payback_with_data) }
    let(:points_amount) { 750 }

    let!(:locked_payback_transaction) {
      create(
        :payback_transaction,
        :with_inquiry_category,
        :book,
        mandate: mandate,
        points_amount: points_amount,
        state: "locked"
      )
    }

    let!(:created_payback_transaction) {
      create(
        :payback_transaction,
        :with_inquiry_category,
        :book,
        mandate: mandate,
        points_amount: points_amount,
        state: "created"
      )
    }

    let!(:completed_payback_transaction) {
      create(
        :payback_transaction,
        :with_inquiry_category,
        :book,
        mandate: mandate,
        points_amount: points_amount,
        state: "completed"
      )
    }

    let!(:refunded_payback_transaction) {
      create(
        :payback_transaction,
        :with_inquiry_category,
        :book,
        mandate: mandate,
        points_amount: points_amount,
        state: "refund_initiated"
      )
    }

    let(:excepted_payback_points) { { "locked" => points_amount, "unlocked" => points_amount } }

    context "when the parameter passed is the id of mandate" do
      it "updates the total amount of points correctly" do
        repository.recalculate_points(mandate.id)
        mandate.reload

        expect(mandate.reload.loyalty["payback"]["rewardedPoints"]).to eq(excepted_payback_points)
      end
    end

    context "when the parameter passed is an instance of Mandate model" do
      it "updates the total amount of points correctly" do
        repository.recalculate_points(mandate)
        mandate.reload

        expect(mandate.reload.loyalty["payback"]["rewardedPoints"]).to eq(excepted_payback_points)
      end
    end
  end

  describe "#reset_points_for_all_customers" do
    let!(:mandate_with_payback_data) { create(:mandate, :payback_with_data, state: "accepted") }
    let!(:mandate_enabled_payback) { create(:mandate, :payback, state: "accepted") }

    it "recalculates the points only for mandate with payback number" do
      expect(repository).to receive(:recalculate_points).with(mandate_with_payback_data)

      repository.reset_points_for_all_customers
    end
  end

  describe "#with_payback_number_in_batches" do
    let!(:payback_mandate_with_number) { create(:mandate, :payback_with_data) }
    let!(:payback_mandate_without_number) { create(:mandate, :payback) }

    it "yields with batch which contains mandate with payback number" do
      expect { |block|
        repository.with_payback_number_in_batches(&block)
      }.to yield_with_args([having_attributes(id: payback_mandate_with_number.id)])
    end
  end

  describe "#customers_to_send_number_reminder" do
    let(:from_time) { 14.days.ago }
    let(:to_time) { 7.days.ago.end_of_day }
    let(:document_type) { "add_payback_number_reminder" }

    context "when customer has already added the payback number" do
      let!(:mandate) { create(:mandate, :accepted, :payback_with_data) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 6.hours
        )
      end

      it "doesn't return any customer" do
        customers = repository.customers_to_send_number_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(0)
      end
    end

    context "when customer has already received the reminder" do
      let!(:mandate) { create(:mandate, :accepted, user: create(:user, :payback_enabled)) }

      let!(:document) do
        create(:document, documentable: mandate, document_type: DocumentType.add_payback_number_reminder)
      end

      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 1.day
        )
      end

      it "doesn't return any customer" do
        customers = repository.customers_to_send_number_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(0)
      end
    end

    context "when customer is not accepted" do
      let!(:mandate) { create(:mandate, :payback) }

      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 1.day
        )
      end

      it "doesn't return any customer" do
        customers = repository.customers_to_send_number_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(0)
      end
    end

    context "when customer is accepted within interval and didn't add payback number" do
      let!(:mandate) { create(:mandate, :accepted, user: create(:user, :payback_enabled)) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 10.hours
        )
      end

      it "returns the customer" do
        customers = repository.customers_to_send_number_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(1)
        expect(customers[0]).to be_kind_of(Payback::Entities::Customer)
        expect(customers[0].id).to eq(mandate.id)
      end
    end

    context "when customer is accepted out of the interval and didn't add payback number" do
      let!(:mandate) { create(:mandate, :accepted, user: create(:user, :payback_enabled)) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: from_time - 10.hours
        )
      end

      it "doesn't return any customer" do
        customers = repository.customers_to_send_number_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(0)
      end
    end
  end

  describe "#customers_to_send_inquiries_reminder" do
    let(:from_time) { 14.days.ago }
    let(:to_time) { 7.days.ago.end_of_day }
    let(:document_type) { "payback_inquiries_reminder" }

    context "when customer has already received the reminder" do
      let!(:mandate) { create(:mandate, :accepted, user: create(:user, :payback_enabled)) }

      let!(:document) do
        create(:document, documentable: mandate, document_type: DocumentType.payback_inquiries_reminder)
      end

      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 1.day
        )
      end

      it "doesn't return any customer" do
        customers = repository.customers_to_send_inquiries_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(0)
      end
    end

    context "when customer is not accepted" do
      let!(:mandate) { create(:mandate, :payback) }

      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 1.day
        )
      end

      it "doesn't return any customer" do
        customers = repository.customers_to_send_inquiries_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(0)
      end
    end

    context "when customer is accepted within interval" do
      let!(:mandate) { create(:mandate, :accepted, user: create(:user, :payback_enabled)) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 10.hours
        )
      end

      it "returns the customer" do
        customers = repository.customers_to_send_inquiries_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(1)
        expect(customers[0]).to be_kind_of(Payback::Entities::Customer)
        expect(customers[0].id).to eq(mandate.id)
      end
    end

    context "when customer is accepted out of the interval" do
      let!(:mandate) { create(:mandate, :accepted, user: create(:user, :payback_enabled)) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: from_time - 10.hours
        )
      end

      it "doesn't return any customer" do
        customers = repository.customers_to_send_inquiries_reminder(from_time, to_time, document_type)

        expect(customers.length).to eq(0)
      end
    end
  end

  describe "#customers_to_send_inquiry_complete_reminder" do
    subject(:customers) { repository.customers_to_send_inquiry_complete_reminder(from_time, to_time, document_type) }

    let(:now) { Time.current }
    let(:from_time) { now - 15.weeks }
    let(:to_time) { now - 10.weeks }
    let(:reward_period) { 14.days }
    let(:document_type) { "payback_inquiry_complete_reminder" }

    let(:user) { create(:user, :payback_enabled) }
    let(:inquiry) { create(:inquiry, mandate: mandate) }
    let(:category) { create(:category) }
    let(:mandate_accepted_at) { to_time - reward_period }
    let(:inquiry_category_created_at) { mandate_accepted_at + reward_period / 2 }

    let!(:mandate) { create(:mandate, :accepted, user: user) }
    let!(:accepted_event) do
      create(
        :business_event,
        entity: mandate,
        action: "accept",
        created_at: mandate_accepted_at
      )
    end
    let!(:inquiry_category) do
      create(
        :inquiry_category,
        :in_progress,
        inquiry: inquiry,
        category: category,
        created_at: inquiry_category_created_at
      )
    end
    let(:another_good_inquiry_category) do
      create(
        :inquiry_category,
        :in_progress,
        inquiry: inquiry,
        category: create(:category),
        created_at: mandate_accepted_at
      )
    end

    before { Timecop.freeze(now) }
    after { Timecop.return }

    it { expect(customers).to include(an_object_having_attributes(id: mandate.id)) }
    it { expect(customers).to include(a_kind_of(Payback::Entities::Customer)) }

    context "when reminder already sent" do
      before { create(:document, documentable: mandate, document_type: DocumentType.send(document_type)) }

      it { expect(customers).to be_empty }
    end

    context "when mandate is not accepted" do
      before { mandate.revoke }

      it { expect(customers).to be_empty }
    end

    context "when inquiry_category in not in progress" do
      before { inquiry_category.complete }

      it { expect(customers).to be_empty }

      context "when there is another inquiry_category in progress" do
        before { another_good_inquiry_category }

        it { expect(customers).to include(an_object_having_attributes(id: mandate.id)) }
        it { expect(customers).to include(a_kind_of(Payback::Entities::Customer)) }
      end
    end

    context "when customer is non-payback one" do
      let(:user) { create(:user) }

      it { expect(customers).to be_empty }
    end

    context "when customer is accepted before interval" do
      let(:mandate_accepted_at) { from_time - 1.day }

      it { expect(customers).to be_empty }
    end

    context "when customer is accepted after interval" do
      let(:mandate_accepted_at) { to_time + 1.day }

      it { expect(customers).to be_empty }
    end

    context "when inquiry is created after reward period" do
      let(:inquiry_category_created_at) { mandate_accepted_at + reward_period + 1.day }

      it { expect(customers).to be_empty }

      context "when there is another inquiry_category crated within reward period" do
        before { another_good_inquiry_category }

        it { expect(customers).to include(an_object_having_attributes(id: mandate.id)) }
        it { expect(customers).to include(a_kind_of(Payback::Entities::Customer)) }
      end
    end

    Payback::Entities::InquiryCategory::NOT_REWARDABLE_CATEGORY_IDENTIFIERS.each do |category_ident|
      context "when the inquiry_category's category is #{category_ident}" do
        let(:category) { create(:category, ident: category_ident) }

        it { expect(customers).to be_empty }

        context "when there is rewardable inquiry_category" do
          before { another_good_inquiry_category }

          it { expect(customers).to include(an_object_having_attributes(id: mandate.id)) }
          it { expect(customers).to include(a_kind_of(Payback::Entities::Customer)) }
        end
      end
    end
  end

  describe "#save_sanity_check_result" do
    context "when sanity check result is false" do
      let(:payback_mandate) { create(:mandate, :payback_with_data) }
      let(:expected_points) { 1500 }
      let(:sanity_check) { false }

      it "creates sanity_check hash in payback_data with result and expected points amount" do
        repository.save_sanity_check_result(payback_mandate.id, sanity_check, expected_points)

        payback_mandate.reload

        expect(payback_mandate.loyalty["payback"]["sanity_check"]["result"]).to be_falsey
        expect(payback_mandate.loyalty["payback"]["sanity_check"]["expected_points_amount"]).to eq(expected_points)
      end
    end

    context "when sanity check result is true" do
      let(:payback_mandate) {
        create(
          :mandate,
          :payback_with_data,
          loyalty: {
            payback: {
              "paybackNumber" => Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX),
              "rewardedPoints" => {
                "locked" => 750,
                "unlocked" => 0
              },
              "sanity_check" => {
                "result" => false,
                "expected_points_amount" => 1500
              }
            }
          }
        )
      }

      let(:expected_points) { 750 }
      let(:sanity_check) { true }

      it "deleted sanity_check hash in payback_data" do
        repository.save_sanity_check_result(payback_mandate.id, sanity_check, expected_points)

        payback_mandate.reload

        expect(payback_mandate.loyalty["payback"]["sanity_check"]).to be_nil
      end
    end
  end

  describe "#accepted_between_in_batches" do
    let(:from_time) { 14.days.ago }
    let(:to_time) { 7.days.ago.end_of_day }

    context "when payback customer is accepted within interval" do
      let!(:mandate) { create(:mandate, :accepted, :payback_with_data) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 10.hours
        )
      end

      it "yields with array including customer as argument" do
        expect { |block|
          repository.accepted_between_in_batches(from_time, to_time, &block)
        }.to yield_with_args([having_attributes(id: mandate.id)])
      end
    end

    context "when customer is not accepted" do
      let!(:mandate) { create(:mandate, :payback_with_data) }

      it { expect { |b| repository.accepted_between_in_batches(from_time, to_time, &b) }.not_to yield_control }
    end

    context "when customer is accepted out of the interval" do
      let!(:mandate) { create(:mandate, :accepted, :payback_with_data) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: from_time - 10.hours
        )
      end

      it { expect { |b| repository.accepted_between_in_batches(from_time, to_time, &b) }.not_to yield_control }
    end

    context "when accepted customer does not have payback as source" do
      let!(:mandate) { create(:mandate, :accepted) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 10.hours
        )
      end

      it { expect { |b| repository.accepted_between_in_batches(from_time, to_time, &b) }.not_to yield_control }
    end

    context "when accepted customer does not have payback number" do
      let!(:mandate) { create(:mandate, :accepted, :payback_with_data, paybackNumber: nil) }
      let!(:accepted_event) do
        create(
          :business_event,
          entity_type: "Mandate",
          action: "accept",
          entity_id: mandate.id,
          created_at: to_time - 10.hours
        )
      end

      it { expect { |b| repository.accepted_between_in_batches(from_time, to_time, &b) }.not_to yield_control }
    end
  end
end
