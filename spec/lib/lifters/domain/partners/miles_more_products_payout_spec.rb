# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Partners::MilesMoreProductsPayout do
  let(:mandate) { create(:mandate, :with_accepted_tos, :mam) }
  let(:subject) { described_class.new(mandate) }

  context "#build_loyalty_bookings" do
    it "returns an empty array if mandate is not mam_enabled" do
      non_mam_mandate = build(:mandate)
      expect(described_class.new(non_mam_mandate).build_loyalty_bookings).to eq([])
    end

    it "returns an empty array if mandate is mam_enabled but no loyalty group can be mapped to the mandate" do
      expect(subject.build_loyalty_bookings).to eq([])
    end

    context "with loyalty group and mandate products" do
      let!(:loyalty_group) { create(:mam_loyalty_group, default_fallback: true) }
      let!(:product) { create(:product, mandate: mandate) }

      it "calls build_product_loyalty_bookings for each mandate products if there is a loyalty group \
        for the mandate and there is no previous booking for that product" do
        expect_any_instance_of(described_class).to receive(:build_product_loyalty_bookings)
        subject.build_loyalty_bookings
      end

      it "will not call build_product_loyalty_bookings for a mandate products if there is a loyalty group \
        for the mandate and there is a previous booking for that product" do
        expect_any_instance_of(described_class).not_to receive(:build_product_loyalty_bookings)
        create(:loyalty_booking, bookable: product)
        subject.build_loyalty_bookings
      end

      it "will ignore the previous booking if the ignore flag is passed to the method" do
        expect_any_instance_of(described_class).to receive(:build_product_loyalty_bookings)
        create(:loyalty_booking, bookable: product)
        subject.build_loyalty_bookings(true)
      end
    end
  end

  context "#build_product_loyalty_bookings" do
    let(:valid_product) {
      instance_double(Product, gkv?: false, grv?: false, sold_by_us?: false, state: :details_available)
    }
    let(:payout_rule) { create(:mam_payout_rule, products_count: 1) }

    it "returns nil if called with an invalid for payout product" do
      invalid_product = instance_double(Product, gkv?: true, grv?: false, state: :details_available)
      expect(subject.build_product_loyalty_bookings(invalid_product, 1, payout_rule.mam_loyalty_group)).to be_nil
    end

    it "returns nil if called with a valid for payout product but no matching rule could be found" do
      expect(subject.build_product_loyalty_bookings(valid_product, 2, payout_rule.mam_loyalty_group)).to be_nil
    end

    it "creates a new instance of product loyalty booking with main miles \
       if product valid and miles found and positive miles returned from get miles method" do
      allow_any_instance_of(described_class).to receive(:get_miles).and_return(main_miles: 1000, extra_miles: 0)
      expect(Domain::Partners::MamProductLoyaltyBooking).to receive(:new).with(valid_product, 1000, any_args)
      subject.build_product_loyalty_bookings(valid_product, 1, payout_rule.mam_loyalty_group)
    end

    it "creates a new instance of product loyalty booking with extra miles \
       if product valid and miles found and positive miles returned from get miles method" do
      allow_any_instance_of(described_class).to receive(:get_miles).and_return(main_miles: 0, extra_miles: 1000)
      expect(Domain::Partners::MamProductLoyaltyBooking).to receive(:new).with(valid_product, 1000, any_args)
      subject.build_product_loyalty_bookings(valid_product, 1, payout_rule.mam_loyalty_group)
    end
  end

  context "#get_miles" do
    let(:mam_loyalty_group) { create(:mam_loyalty_group) }
    let(:main_payout_rule) { create(:mam_payout_rule, mam_loyalty_group: mam_loyalty_group) }
    let(:mam_customer_type) { "base" }

    context "without a base loyalty group" do
      it "returns the payout rule amount mapping to mam mandate type as main miles" do
        miles_hash = subject.get_miles(mam_customer_type, mam_loyalty_group, main_payout_rule)
        expect(miles_hash[:main_miles]).to eq(main_payout_rule.send(mam_customer_type))
      end

      it "always returns 0 for the extra_miles" do
        miles_hash = subject.get_miles(mam_customer_type, mam_loyalty_group, main_payout_rule)
        expect(miles_hash[:extra_miles]).to eq(0)
      end
    end

    context "with base loyalty group" do
      let(:with_base_loyalty_group) { create(:mam_loyalty_group, base_loyalty_group: mam_loyalty_group) }
      let(:with_base_payout_rule) { create(:mam_payout_rule, mam_loyalty_group: with_base_loyalty_group) }

      it "will return 0 in the extra miles if the base group has no rule for the same products count" do
        with_base_payout_rule.products_count = main_payout_rule.products_count + 1
        miles_hash = subject.get_miles(mam_customer_type, with_base_loyalty_group, with_base_payout_rule)
        expect(miles_hash[:extra_miles]).to eq(0)
      end

      it "will return 0 in the extra miles if the base group has a rule but with more miles than the main rule" do
        with_base_payout_rule.base = main_payout_rule.base - 100
        miles_hash = subject.get_miles(mam_customer_type, with_base_loyalty_group, with_base_payout_rule)
        expect(miles_hash[:extra_miles]).to eq(0)
      end

      it "returns the main miles as the base payout mapping to mandate mam type if there is \
          a base rule with less miles than the main payout rule" do
        with_base_payout_rule.base = main_payout_rule.base + 100
        miles_hash = subject.get_miles(mam_customer_type, with_base_loyalty_group, with_base_payout_rule)
        expect(miles_hash[:main_miles]).to eq(main_payout_rule.base)
      end

      it "returns the extra miles as the differnce between the main and base payouts if there is \
          a base rule with less miles than the main payout rule" do
        with_base_payout_rule.base = main_payout_rule.base + 100
        miles_hash = subject.get_miles(mam_customer_type, with_base_loyalty_group, with_base_payout_rule)
        expect(miles_hash[:extra_miles]).to eq(100)
      end
    end
  end

  context "#valid?" do
    (Product.state_machine.states.keys - Product::MAM_PAID_OUT_STATES).each do |invalid_state|
      it "should not be valid for the state #{invalid_state}" do
        product = instance_double(Product, gkv?: false, grv?: false, state: invalid_state)
        expect(subject.send(:valid?, product)).to be_falsey
      end
    end

    Product::MAM_PAID_OUT_STATES.each do |valid_state|
      it "should be valid for the state #{valid_state}" do
        product = instance_double(Product, gkv?: false, grv?: false, state: valid_state)
        expect(subject.send(:valid?, product)).to be_truthy
      end
    end

    it "is not valid for a GKV product" do
      product = instance_double(Product, gkv?: true, grv?: false, state: :details_available)
      expect(subject.send(:valid?, product)).to be_falsey
    end

    it "is not valid for a GRV product" do
      product = instance_double(Product, gkv?: false, grv?: true, state: :details_available)
      expect(subject.send(:valid?, product)).to be_falsey
    end
  end

  context "#already_booked?" do
    let(:product) { create(:product, state: :details_available) }

    it "should be true, if there is a loyalty booking" do
      create(:loyalty_booking, bookable: product)
      expect(subject.send(:already_booked?, product)).to be_truthy
    end

    it "should be false, if there is no loyalty booking" do
      expect(subject.send(:already_booked?, product)).to be_falsey
    end
  end

  context "#gkv?" do
    it "returns true if the product is a gkv product" do
      product = instance_double(Product, gkv?: true, state: :details_available)
      expect(subject.send(:gkv?, product)).to be_truthy
    end

    it "returns false if the product is not a gkv product" do
      product = instance_double(Product, gkv?: false, state: :details_available)
      expect(subject.send(:gkv?, product)).to be_falsey
    end
  end

  context "#grv?" do
    it "returns true if the product is a grv product" do
      product = instance_double(Product, grv?: true, state: :details_available)
      expect(subject.send(:grv?, product)).to be_truthy
    end

    it "returns false if the product is not a grv product" do
      product = instance_double(Product, grv?: false, state: :details_available)
      expect(subject.send(:grv?, product)).to be_falsey
    end
  end

  context "#get_booking_code" do
    it "returns the under management product booking code if not sold by us" do
      product = instance_double(Product, sold_by_us?: false, state: :details_available)
      expect(subject.send(:get_booking_code, product)).to eq(described_class::MANAGED_INSURANCE_PRODUCT_CODE)
    end

    it "returns the sold by us product booking code if sold by us" do
      product = instance_double(Product, sold_by_us?: true, state: :details_available)
      expect(subject.send(:get_booking_code, product)).to eq(described_class::SOLD_BY_US_PRODUCT_CODE)
    end

    it "will always return the prmotional booking code if it is not base miles" do
      product = instance_double(Product, sold_by_us?: true, state: :details_available)
      expect(subject.send(:get_booking_code, product, false)).to eq(described_class::PROMOTION_BOOKING_CODE)
    end
  end
end
