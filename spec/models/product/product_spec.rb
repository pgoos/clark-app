# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  # Setup
  subject { FactoryBot.build(:product) }

  it { is_expected.to be_valid }

  # Traits
  %i[
    cheap_product
    retirement_equity_product
    retirement_equity_category
    with_advisory_documentation
  ].each do |trait|
    it "#{trait} should be a valid trait" do
      expect(FactoryBot.build(:product, trait)).to be_valid
    end
  end

  # Settings

  it "defaults to the customer as insurance_holder" do
    expect(Product.new.insurance_holder).to eq("customer")
  end

  it "insurance_holder can hold 'third_party' value" do
    subject.insurance_holder = :third_party
    expect(subject.insurance_holder).to eq("third_party")
  end

  %i[premium_price_cents portfolio_commission_price_cents acquisition_commission_price_cents].each do |attr|
    it { is_expected.to monetize(attr) }
  end

  it "sets sold_by to 'others' by default" do
    expect(described_class.new).to be_sold_by_others
  end

  # Constants
  # Attribute Settings

  it "should serialize the value type means of payment" do
    subject.means_of_payment = ValueTypes::MeansOfPayment::INVOICE
    expect(subject.means_of_payment).to eq(ValueTypes::MeansOfPayment::INVOICE)
  end

  # Plugins
  # Concerns

  it_behaves_like "a commentable model"
  it_behaves_like "a commissionable model"
  it_behaves_like "event_publishable", :publishable
  it_behaves_like "a documentable"

  context "skipping the transition hooks" do
    before do
      allow_any_instance_of(Product).to receive(:halt_when_advisory_documentation_not_present).with(any_args)
      allow_any_instance_of(Product).to receive(:can_be_canceled_by_customer).and_return(true)
      allow(Settings).to receive_message_chain(:app_features, :self_service_products) { true }
      allow_any_instance_of(Product).to receive(:sold_by_others?).and_return(false)
    end

    it_behaves_like "an auditable model"
  end

  it_behaves_like "a model with coverages"

  # State Machine
  # see ./spec/models/product_state_machine_spec.rb

  # Scopes
  # see ./spec/models/product_scopes_spec.rb

  # Associations
  # see ./spec/models/product_associations_spec.rb

  # Nested Attributes

  it { expect(subject).to accept_nested_attributes_for(:documents) }

  # Validations
  # see ./spec/models/product_validations_spec.rb

  # Callbacks
  context "callbacks" do
    it { expect(subject).to callback(:publish_created_event).after(:create) }
    it { expect(subject).to callback(:publish_updated_event_for_data_fields).after(:update) }
    it { expect(subject).to callback(:publish_deleted_event).after(:destroy) }

    context "when updating attributes" do
      subject { create(:product) }

      before { stub_const("Product::ATTRIBUTES_CAUSE_ADVICE_INVALIDATION", []) }

      it "does not broadcast advice invalidated event" do
        expect(subject).not_to receive(:broadcast).with(:product_advice_invalidated, subject)
        subject.update!(number: "foo")
      end

      context "when attributes are causing advice invalidation" do
        before { stub_const("Product::ATTRIBUTES_CAUSE_ADVICE_INVALIDATION", ["number"]) }

        it "broadcasts an event" do
          expect(subject).to receive(:broadcast).with(:product_advice_invalidated, subject)
          subject.update!(number: "FOO-BAR")
        end
      end
    end
  end

  context "resetting contract end date on load" do
    let(:mandate) { create(:mandate, :accepted) }

    before do
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    described_class::STATES_OF_ACTIVE_PRODUCTS.except("termination_pending").each do |state|
      it "changes the contract end_date when it was passed and is in state #{state}" do
        product = create(
          :product,
          state:             state,
          contract_ended_at: 1.day.ago,
          renewal_period:    5,
          mandate:           mandate
        )
        product.renew_contract!
        expect(product.contract_ended_at.to_date).to eq(1.day.ago.to_date + 5.months)
      end
    end

    it "does not the contract end_date for a revoked customer" do
      initial_contract_ended_at = 1.day.ago
      product = create(
        :product,
        state:             "under_management",
        contract_ended_at: initial_contract_ended_at,
        renewal_period:    5,
        mandate:           create(:mandate, :revoked)
      )
      product.renew_contract!
      expect(product.contract_ended_at.to_date).to eq(initial_contract_ended_at.to_date)
    end

    it "adds multiple amounts of renewal_period until we reached the future" do
      product = create(
        :product, state: "under_management",
        contract_ended_at: 11.months.ago.at_beginning_of_month, renewal_period: 5,
        mandate: mandate
      )

      product.renew_contract!

      expect(product.contract_ended_at.to_date)
        .to eq(11.months.ago.at_beginning_of_month.to_date + 15.months)
    end

    ( # Product states to not update the contract_ended_at date:
      Product.state_machine.states.keys -
        Product::STATES_OF_ACTIVE_PRODUCTS.except("termination_pending").map(&:to_sym)
    ).each do |state|
      it "does not change the end date if the product is in state #{state}" do
        initial_contract_endet_at = 1.day.ago
        product = create(
          :product,
          state:             state,
          contract_ended_at: initial_contract_endet_at,
          renewal_period:    5,
          mandate:           mandate
        )

        product.renew_contract!

        expect(product.contract_ended_at.to_date).to eq(initial_contract_endet_at.to_date)
      end
    end

    it "does not change the end date if the product is canceled" do
      product = create(
        :product, state: "canceled", contract_ended_at: 1.day.ago, renewal_period: 5,
        mandate: mandate
      )

      product.renew_contract!

      expect(product.contract_ended_at.to_date).to eq(1.day.ago.to_date)
    end

    it "does not change the end date if the product does not have an end date" do
      product = create(
        :product, state: "under_management", contract_ended_at: nil, renewal_period: 5,
        mandate: mandate
      )

      product.renew_contract!

      expect(product.contract_ended_at).to eq(nil)
    end

    it "does not change the end date if the product does not have a renewal period" do
      product = create(
        :product, state: "under_management", contract_ended_at: 1.day.ago, renewal_period: nil,
        mandate: mandate
      )

      product.renew_contract!

      expect(product.contract_ended_at.to_date).to eq(1.day.ago.to_date)
    end

    it "does not change the end date if the end date has not been reached" do
      product = create(
        :product, state: "under_management", contract_ended_at: 1.day.from_now, renewal_period: 5,
        mandate: mandate
      )

      product.renew_contract!

      expect(product.contract_ended_at.to_date).to eq(1.day.from_now.to_date)
    end
  end

  describe "#terminated_and_not_ended?" do
    let(:product) { build(:product, :terminated, contract_ended_at: contract_ended_at) }

    context "state is terminated" do
      context "contract not ended" do
        let(:contract_ended_at) { 2.days.from_now }

        it "return true" do
          expect(product.terminated_and_not_ended?).to eq(true)
        end
      end

      context "contract ended" do
        let(:contract_ended_at) { 2.days.ago }

        it "return false" do
          expect(product.terminated_and_not_ended?).to eq(false)
        end
      end
    end
  end

  describe "#net_payment_amount_sales" do
    [
      [100, 3, 3, 94],
      [100, 0, 3, 97],
      [100, 3, 0, 97],
      [100, 0.32, 0, 99.68],
      [100, 0, 0, 100],
      [0, 0, 0, 0],
      [10, nil, nil, 10]
    ].each do |test_case|
      context "acquisition_commission_price = #{test_case[0]}" do
        context "deduction_reserve_sales = #{test_case[1]}" do
          context "deduction_fidelity_sales = #{test_case[2]}" do
            let(:product) do
              build(:product, :terminated, acquisition_commission_price: test_case[0],
                                           deduction_reserve_sales: test_case[1],
                                           deduction_fidelity_sales: test_case[2])
            end

            it "returns #{test_case[3]}" do
              expect(product.net_payment_amount_sales).to eq test_case[3]
            end
          end
        end
      end
    end
  end

  context "default scope" do
    let!(:regular_product) { create(:product) }
    let!(:shared_product)  { create(:product, :shared_contract) }

    it "doesn't contain products with 'third_party' insurance holder" do
      products = Product.all
      expect(products.length).to eq(1)
      expect(products.first).to  eq(regular_product)
    end
  end

  # Delegates
  # see ./spec/models/product_methods_spec.rb

  # Instance Methods
  # see ./spec/models/product_methods_spec.rb

  # Class Methods
  # see ./spec/models/product_methods_spec.rb
end
