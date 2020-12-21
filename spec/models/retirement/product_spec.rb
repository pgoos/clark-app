# frozen_string_literal: true

# == Schema Information
#
# Table name: retirement_products
#
#  id                                                     :integer          not null, primary key
#  category                                               :integer          default(0), not null
#  document_date                                          :date
#  retirement_date                                        :date
#  guaranteed_pension_continueed_payment_cents            :integer          default(0), not null
#  guaranteed_pension_continueed_payment_currency         :string           default("EUR"), not null
#  guaranteed_pension_continueed_payment_monthly_currency :string           default("EUR"), not null
#  guaranteed_pension_continueed_payment_payment_type     :integer          default("monthly"), not null
#  surplus_retirement_income_cents                        :integer          default(0), not null
#  surplus_retirement_income_currency                     :string           default("EUR"), not null
#  surplus_retirement_income_monthly_currency             :string           default("EUR"), not null
#  surplus_retirement_income_payment_type                 :integer          default("monthly"), not null
#  retirement_three_percent_growth_cents                  :integer          default(0), not null
#  retirement_three_percent_growth_currency               :string           default("EUR"), not null
#  retirement_three_percent_growth_monthly_currency       :string           default("EUR"), not null
#  retirement_three_percent_growth_payment_type           :integer          default("monthly"), not null
#  retirement_factor_cents                                :integer          default(0), not null
#  retirement_factor_currency                             :string           default("EUR"), not null
#  retirement_factor_monthly_currency                     :string           default("EUR"), not null
#  retirement_factor_payment_type                         :integer          default("monthly"), not null
#  fund_capital_three_percent_growth_cents                :integer          default(0), not null
#  fund_capital_three_percent_growth_currency             :string           default("EUR"), not null
#  guaranteed_capital_cents                               :integer          default(0), not null
#  guaranteed_capital_currency                            :string           default("EUR"), not null
#  equity_today_cents                                     :integer          default(0), not null
#  equity_today_currency                                  :string           default("EUR"), not null
#  possible_capital_including_surplus_cents               :integer          default(0), not null
#  possible_capital_including_surplus_currency            :string           default("EUR"), not null
#  pension_capital_today_cents                            :integer          default(0), not null
#  pension_capital_today_currency                         :string           default("EUR"), not null
#  pension_capital_three_percent_cents                    :integer          default(0), not null
#  pension_capital_three_percent_currency                 :string           default("EUR"), not null
#  created_at                                             :datetime         not null
#  updated_at                                             :datetime         not null
#  type                                                   :string
#  product_id                                             :integer
#  state                                                  :string
#  forecast                                               :integer          default("document")
#

require "rails_helper"

RSpec.describe Retirement::Product, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  it_behaves_like "a documentable"

  # State Machine
  # Scopes

  describe ".active" do
    context "when created" do
      it "returns the product" do
        retirement_product = create(:retirement_product, state: :created)
        expect(Retirement::Product.active).to include retirement_product
      end
    end

    context "when details_available" do
      it "returns the product" do
        retirement_product = create(:retirement_product, state: :details_available)
        expect(Retirement::Product.active).to include retirement_product
      end
    end

    context "when not in created or details_available" do
      it "doesn't return the product" do
        retirement_product = create(:retirement_product, state: :information_required)
        expect(Retirement::Product.active).not_to include retirement_product
      end
    end
  end

  describe ".inactive" do
    context "when information_required" do
      it "returns the product" do
        retirement_product = create(:retirement_product, state: :information_required)
        expect(Retirement::Product.inactive).to include retirement_product
      end
    end

    context "when out_of_scope" do
      it "returns the product" do
        retirement_product = create(:retirement_product, state: :out_of_scope)
        expect(Retirement::Product.inactive).to include retirement_product
      end
    end

    context "when not in information_required or out_of_scope" do
      it "doesn't return the product" do
        retirement_product = create(:retirement_product, state: :details_available)
        expect(Retirement::Product.inactive).not_to include retirement_product
      end
    end
  end

  # Associations
  it { is_expected.to have_many(:documents) }
  it { is_expected.to belong_to(:product) }
  # Nested Attributes
  # Validations
  # Callbacks
  # Instance Methods
  # Class Methods

  describe "state machine" do
    context "when created" do
      subject { build :retirement_product, :created }

      it "can request infromation" do
        subject.request_information
        expect(subject).to be_information_required
      end
    end

    context "when details_available" do
      subject { build :retirement_product, :details_available }

      it "can request infromation" do
        subject.request_information
        expect(subject).to be_information_required
      end
    end

    context "when information_required" do
      subject { build :retirement_product, :information_required }

      it "can't request infromation" do
        expect(subject.can_request_information?).to eq false
      end
    end

    context "when out_of_scope" do
      subject { build :retirement_product, :out_of_scope }

      it "can't request infromation" do
        expect(subject.can_request_information?).to eq false
      end
    end

    context "when transitioning to information_required" do
      subject { build :retirement_product, :created }

      it "does not erase requested_information" do
        subject.requested_information = %w[foo bar]
        subject.information_requested_at = Time.zone.now
        subject.request_information!
        expect(subject.requested_information).to eq %w[foo bar]
        expect(subject.information_requested_at).to be_present
      end
    end

    context "when transitioning to other than information_required" do
      subject { build :retirement_product, :information_required }

      it "erases requested_information" do
        subject.requested_information = %w[foo bar]
        subject.information_requested_at = Time.zone.now
        subject.details_saved!
        expect(subject.requested_information).to eq []
        expect(subject.information_requested_at).to be_blank
      end
    end
  end

  describe "#forecast" do
    it do
      is_expected.to define_enum_for(:forecast).with(%i[document initial customer])
    end
  end

  describe "#incomplete?" do
    context "when category and type are nil" do
      let(:retirement_product) { build_stubbed(:retirement_product) }

      it { expect(retirement_product).to be_incomplete }
    end

    context "when category and type are set" do
      let(:retirement_product) { build_stubbed(:retirement_state_product) }

      it { expect(retirement_product).not_to be_incomplete }
    end
  end

  shared_examples "monthly payment methods" do |monthly_attribute, yearly_attirbute|
    context "when payment type is annually" do
      let(:retirement_product) { build_stubbed(:retirement_product, :with_annual_values) }

      it do
        expect(retirement_product.send(monthly_attribute))
          .to eq(retirement_product.send(yearly_attirbute) / 12)
      end
    end

    context "when payment type is monthly" do
      let(:retirement_product) { build_stubbed(:retirement_product, :with_monthly_values) }

      it do
        expect(retirement_product.send(monthly_attribute))
          .to eq(retirement_product.send(yearly_attirbute))
      end
    end
  end

  describe "#surplus_retirement_income_monthly_cents" do
    it_behaves_like "monthly payment methods",
                    :surplus_retirement_income_monthly_cents,
                    :surplus_retirement_income_cents
  end

  describe "#retirement_three_percent_growth_monthly_cents" do
    it_behaves_like "monthly payment methods",
                    :retirement_three_percent_growth_monthly_cents,
                    :retirement_three_percent_growth_cents
  end

  describe "#retirement_factor_monthly_cents" do
    it_behaves_like "monthly payment methods",
                    :retirement_factor_monthly_cents,
                    :retirement_factor_cents
  end

  describe "#guaranteed_pension_continueed_payment_monthly_cents" do
    it_behaves_like "monthly payment methods",
                    :guaranteed_pension_continueed_payment_monthly_cents,
                    :guaranteed_pension_continueed_payment_cents
  end
end
