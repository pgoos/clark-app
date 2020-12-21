# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  subject { build(:product, inquiry: build_stubbed(:inquiry)) }

  describe "contract start and end dates" do
    context "contract_started_at" do
      it "is required for regular products" do
        expect(Product.new(premium_state: "premium")).to validate_presence_of(:contract_started_at)
      end

      it "is not required if premium_state is salary" do
        expect(Product.new(premium_state: "salary")).not_to validate_presence_of(:contract_started_at)
      end

      %w[offered ordered order_pending canceled].each do |state|
        it "is not required for the offer life cycle state #{state}" do
          expect(Product.new(state: state)).not_to validate_presence_of(:contract_started_at)
        end
      end
    end

    describe "contract_ended_at" do
      around do |example|
        Timecop.freeze(t0)
        example.run
        Timecop.return
      end

      let(:t0) { Time.zone.parse("Thu, 07 Jun 2019 12:00:00 CEST +02:00") }
      let(:time_difference) { 1.second }

      describe "validity of the time sequence" do
        it "is not valid if contract_ended_at is before contract_started_at" do
          subject.contract_started_at = t0 + time_difference
          subject.contract_ended_at = t0
          expect(subject).not_to be_valid
        end

        it "should provide an error message, if sequence is flipped" do
          subject.contract_started_at = t0 + time_difference
          subject.contract_ended_at = t0
          expected_message = I18n.t(
            "activerecord.errors.models.product.contract_date_sequence.flipped",
            contract_started_at: subject.contract_started_at,
            contract_ended_at: subject.contract_ended_at
          )

          subject.valid?
          message = subject.errors.messages[:contract_ended_at].first

          expect(message).not_to match(/translation missing/)
          expect(message).to eq(expected_message)
        end

        it "should not validate, if the value did not change" do
          subject.contract_started_at = t0 + time_difference
          subject.save!
          subject.update_attribute(:contract_ended_at, t0)
          expect(subject).to be_persisted
          expect(subject).to be_valid
        end

        it "should validate, if the contract started at did change" do
          subject.contract_started_at = t0 - time_difference
          subject.save!
          subject.update_attribute(:contract_ended_at, t0)
          subject.contract_started_at = t0 + time_difference
          expect(subject).not_to be_valid
        end

        it "does not raise exception when the contract started is nil and contract ended changed" do
          subject.contract_started_at = t0 - time_difference
          subject.save!
          subject.update(contract_ended_at: t0, contract_started_at: nil)
          expect(subject).not_to be_valid
        end
      end

      describe "validity how far the date may be in the future" do
        it "should not validate, if the end date is more than 150 years in the future" do
          subject.contract_started_at = t0
          subject.contract_ended_at = t0 + 151.years
          expect(subject).not_to be_valid
        end

        it "should provide an error message, if the end date is more than 150 years in the future" do
          Timecop.freeze do
            now = Time.zone.now
            subject.contract_started_at = now
            subject.contract_ended_at = now + 151.years
            expected_message = I18n.t(
              "activerecord.errors.models.product.contract_date_sequence.exceeds_lifespan",
              contract_ended_at: subject.contract_ended_at
            )

            subject.valid?
            message = subject.errors.messages[:contract_ended_at].first

            expect(message).not_to match(/translation missing/)
            expect(message).to eq(expected_message)
          end
        end

        it "should not validate, if the value did not change" do
          subject.contract_started_at = t0
          subject.save!
          subject.update_attribute(:contract_ended_at, t0 + 151.years)
          expect(subject).to be_persisted
          expect(subject).to be_valid
        end
      end
    end
  end

  context "contract number" do
    it "is required for regular products" do
      expect(Product.new).to validate_presence_of(:number)
    end

    it "is not requird for offered products" do
      expect(Product.new(state: "offered")).not_to validate_presence_of(:number)
    end

    it "is not requird for ordered products" do
      %w[ordered order_pending].each do |state|
        expect(Product.new(state: state)).not_to validate_presence_of(:number)
      end
    end

    it "is not requird for GKV products" do
      expect(Product.new(premium_state: "salary")).not_to validate_presence_of(:number)
    end

    describe "#number uniquiness" do
      context "when product is customer_provided" do
        let(:product) { create(:product, :customer_provided) }

        it "does not validate" do
          expect(product)
            .not_to validate_uniqueness_of(:number).case_insensitive.allow_nil.allow_blank
        end
      end

      context "when product is a shard one" do
        let(:product) { create(:product, :under_management, :shared_contract) }

        it "does not validate" do
          expect(product)
            .not_to validate_uniqueness_of(:number).case_insensitive.allow_nil.allow_blank
        end
      end

      context "when product is not customer_provided" do
        let(:product) { create(:product, :under_management) }

        it "validates" do
          expect(product)
            .to validate_uniqueness_of(:number).case_insensitive.allow_nil.allow_blank
        end
      end
    end
  end

  context "portfolio commission price" do
    let!(:plan) { FactoryBot.build_stubbed(:plan) }

    context "#plan.transferable?" do
      it "validates numericality when the plan is transferable" do
        allow(plan).to receive(:transferable?).and_return(true)
        expect(Product.new(plan: plan)).to validate_numericality_of(:portfolio_commission_price).is_greater_than_or_equal_to(0)
      end

      it "does not validate numericality when the plan is not transferable" do
        allow(plan).to receive(:transferable?).and_return(false)
        expect(Product.new(plan: plan)).not_to validate_numericality_of(:portfolio_commission_price).is_greater_than(0)
      end

      it "does not validate numericality when the plan is no plan is set" do
        expect(Product.new(plan: nil)).not_to validate_numericality_of(:portfolio_commission_price).is_greater_than(0)
      end

      it "does not validate numericality when the plan is no plan is set" do
        allow(plan).to receive(:transferable?).and_return(true)
        expect(Product.new(plan: plan, portfolio_commission_period: "none")).to validate_numericality_of(:portfolio_commission_price).is_equal_to(0)
      end

      it "does not validate numericality when the product is on_hold" do
        allow(plan).to receive(:transferable?).and_return(true)
        expect(Product.new(plan: plan, premium_state: "on_hold")).not_to validate_numericality_of(:portfolio_commission_price).is_greater_than(0)
      end
    end

    context "state: order_pending -> active product" do
      let(:product_order_pending) do
        Product.new(
          plan:                        plan,
          state:                       "order_pending",
          premium_price:               Money.new(1234, "EUR"),
          premium_period:              "year",
          portfolio_commission_period: "year"
        )
      end

      before do
        allow(plan).to receive(:transferable?).and_return(true)
      end

      it "is an active product, if the order is pending" do
        # Semantically it is heavily questionnable, if order_pending is an active product state!
        # In case the product is not ordered yet, there is no insurance cover for the customer
        # for that product yet!
        expect(described_class::STATES_OF_ACTIVE_PRODUCTS).to include("order_pending")
      end

      it "don't validate numericality, if 'order pending'" do
        expect(product_order_pending).to be_valid
      end

      it "don't validate numericality, if 'order pending' && portfolio_commission_period == none" do
        product_order_pending.portfolio_commission_period = "none"
        expect(product_order_pending).to be_valid
      end
    end
  end

  it { expect(subject).to validate_numericality_of(:acquisition_commission_payouts_count).is_greater_than_or_equal_to(0) }
  it { expect(subject).to validate_numericality_of(:renewal_period).is_greater_than(0).is_less_than_or_equal_to(24) }
  it { expect(subject).to validate_inclusion_of(:premium_period).in_array(Settings.attribute_domains.period) }
  it { expect(subject).to validate_inclusion_of(:premium_state).in_array(Settings.attribute_domains.premium_state) }

  it { expect(subject).to validate_inclusion_of(:portfolio_commission_period).in_array(Settings.attribute_domains.period) }
  it { expect(subject).to validate_inclusion_of(:acquisition_commission_period).in_array(Settings.attribute_domains.period).allow_nil }

  context "when the premium_state is on_hold" do
    it { expect(Product.new(premium_state: "on_hold")).to validate_numericality_of(:premium_price).is_equal_to(0) }
  end

  context "when the premium_period is none" do
    it { expect(Product.new(premium_period: "none")).to validate_numericality_of(:premium_price).is_equal_to(0) }
  end

  context "when the premium_state is salary" do
    it { expect(Product.new(premium_state: "salary")).to validate_numericality_of(:premium_price).is_equal_to(0) }
  end

  context "when the premium_state is premium" do
    it { expect(Product.new(premium_state: "premium")).to validate_numericality_of(:premium_price).is_greater_than(0) }
  end

  context "plan inactive" do
    it "should raise a different error when the plan is empty" do
      product = FactoryBot.build(:product, plan: nil)
      expect(product).not_to be_valid
      expect(product.errors.details[:plan]).to eq [{error: :blank}]
    end

    it "should not allow to create a product, if the given plan is not active" do
      inactive_plan = FactoryBot.build_stubbed(:plan, :deactivated)
      product = FactoryBot.build(:product, plan: inactive_plan)
      expect(product).not_to be_valid
    end

    it "should allow to update a product, if it exists but the plan is not active any more" do
      subject.save!
      subject.plan = build_stubbed(:plan, state: "inactive")
      expect(subject).to be_valid
    end
  end

  context "non detailed product states" do
    Product::NON_DETAILED_PRODUCT_STATES.each do |state|
      it "doesn't validate presence of number for #{state} state" do
        expect(Product.new(state: state)).not_to validate_presence_of(:number)
      end

      it "doesn't validate presence of contract_started_at for #{state} state" do
        expect(Product.new(state: state)).not_to validate_presence_of(:contract_started_at)
      end

      it "doesn't validate presence of plan for #{state} state" do
        expect(Product.new(state: state)).not_to validate_presence_of(:plan)
      end

      it "doesn't validate inclusion of premium_period for #{state} state" do
        expect(Product.new(state: state)).not_to validate_inclusion_of(:premium_period)
      end

      it "doesn't validate numericality greater than 0 of premium_price for #{state} state" do
        expect(Product.new(premium_state: "premium", state: state)).not_to \
          validate_numericality_of(:premium_price).is_greater_than(0)
      end
    end
  end
end
