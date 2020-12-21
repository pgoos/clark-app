# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductPartnerDatum, type: :model do
  # Setup

  let(:mandate) { create(:mandate, gender: :male, state: :accepted, phone: "069 153229339") }
  let(:product) { create(:product, mandate: mandate, premium_price_cents: 11_000, premium_price_currency: "EUR", premium_period: :year) }
  let(:data_attribute) do
    {
      :gender              => mandate.gender,
      :birthdate           => mandate.birthdate.to_date.to_s,
      :premium             => ValueTypes::Money.new(110.00, "EUR"),
      :replacement_premium => ValueTypes::Money.new(89.00, "EUR"),
      :premium_period      => :year,
      "VU"                 => "tarif name", # TODO: Uses a param name specific to DA Direkt. Be generic instead.
    }
  end

  let(:parsed_partner_data) do
    {
      product_id: product.id,
      data:       data_attribute
    }
  end

  let(:product_partner_data_saving) { create(:product_partner_datum, product: product, data: data_attribute) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine

  context "states" do
    subject! { create(:product_partner_datum, product: product, data: data_attribute) }
    let(:shared_example_model) { subject }

    it_behaves_like "an auditable model"

    it "has imported as initial state" do
      expect(subject).to be_imported
    end

    it "may be deferred" do
      subject.defer
      expect(subject).to be_deferred
    end

    it "may be deferred with a reason" do
      subject.defer("a reason")
      expect(subject).to be_deferred
      expect(subject.reason_to_defer).to eq("a reason")
    end
  end

  # Scopes

  context "data scopes" do
    before do
      product_partner_data_saving
    end

    it "should find it for the VU parameter" do
      expect(ProductPartnerDatum.where_data("VU", "tarif name")).to include(product_partner_data_saving)
    end

    it "should not find it, if the VU does not exist" do
      expect(ProductPartnerDatum.where_data("VU", "does not exist")).to be_empty
    end

    it "should not find it for the VU parameter" do
      expect(ProductPartnerDatum.where_not_data("VU", "tarif name")).to be_empty
    end

    it "should find others, if the VU does not exist" do
      expect(ProductPartnerDatum.where_not_data("VU", "does not exist")).to include(product_partner_data_saving)
    end
  end

  # Associations

  it { is_expected.to belong_to(:product) }

  # Nested Attributes
  # Validations

  context "mandate matches" do
    it "should not validate, if the gender does not match" do
      data_attribute[:gender] = :female
      expect(ProductPartnerDatum.new(parsed_partner_data)).not_to be_valid
    end

    it "should validate, if the gender matches" do
      expect(ProductPartnerDatum.new(parsed_partner_data)).to be_valid
    end

    Mandate.state_machine.states.map(&:name).except(:accepted).each do |state|
      it "should not validate for the mandate state #{state}" do
        mandate.update_attributes(state: state)
        expect(ProductPartnerDatum.new(parsed_partner_data)).not_to be_valid
      end
    end
  end

  context "product valid" do
    it "should not validate, if the product id is missing" do
      parsed_partner_data.delete(:product_id)
      expect(ProductPartnerDatum.new(parsed_partner_data)).not_to be_valid
    end

    it "should not validate, if the premium periods do not match" do
      data_attribute[:premium_period] = :month
      expect(ProductPartnerDatum.new(parsed_partner_data)).not_to be_valid
    end

    it "should not validate, if the premium does not match" do
      data_attribute[:premium] = ValueTypes::Money.new(5, "EUR")
      expect(ProductPartnerDatum.new(parsed_partner_data)).not_to be_valid
    end

    it "should not validate, if the replacement premium is lower than 50% of the old premium" do
      # please note: although this looks disturbingly weird, this is one cent:
      one_cent = ::Money.new(1, "EUR")
      too_low = (product.premium_price / 2) - one_cent
      data_attribute[:replacement_premium] = ValueTypes::Money.new(too_low.to_f, "EUR")
      expect(ProductPartnerDatum.new(parsed_partner_data)).not_to be_valid
    end
  end

  # Callbacks
  # Instance Methods

  context "with data" do
    let(:product_partner_data_expensive) do
      data_attribute[:replacement_premium] = ValueTypes::Money.new(110.01, "EUR")
      create(:product_partner_datum, product: product, data: data_attribute)
    end

    context "premium readers" do
      it "should read the old product premium" do
        expect(product_partner_data_saving.old_product_premium).to eq(::Money.new(11_000, "EUR"))
      end

      it "should read the old product premium for a different value" do
        product.update_attributes(premium_price: Money.new(21_000, "USD"))
        data_attribute[:premium] = ValueTypes::Money.new(210, "USD")
        data_attribute[:replacement_premium] = ValueTypes::Money.new(200, "USD")
        expect(product_partner_data_saving.old_product_premium).to eq(::Money.new(21_000, "USD"))
      end

      it "should read the replacement premium for the savings data" do
        expect(product_partner_data_saving.replacement_premium).to eq(::Money.new(8900, "EUR"))
      end

      it "should read the replacement premium for the expensive data" do
        expect(product_partner_data_expensive.replacement_premium).to eq(::Money.new(11_001, "EUR"))
      end
    end

    context "saving" do
      it "should calculate the possible saving from savings data to be 21 €" do
        expect(product_partner_data_saving.possible_saving.to_f).to be_within(0.001).of(21.0)
      end

      it "should calclulate the negative savings for the expensive data" do
        expect(product_partner_data_expensive.possible_saving.to_f).to be_within(0.001).of(-0.01)
      end

      it "should calculate the possible saving according to the form of payment :month" do
        data_attribute[:premium_period] = :month
        product.update_attributes(premium_period: :month)
        expect(product_partner_data_saving.possible_saving.to_f).to be_within(0.001).of(21.0 * 12)
      end

      it "should calculate the possible saving according to the form of payment :month" do
        data_attribute[:premium_period] = :quarter
        product.update_attributes(premium_period: :quarter)
        expect(product_partner_data_saving.possible_saving.to_f).to be_within(0.001).of(21.0 * 4)
      end

      it "should calculate the possible saving according to the form of payment :month" do
        data_attribute[:premium_period] = :half_year
        product.update_attributes(premium_period: :half_year)
        expect(product_partner_data_saving.possible_saving.to_f).to be_within(0.001).of(21.0 * 2)
      end
    end
  end

  # Class Methods
end
