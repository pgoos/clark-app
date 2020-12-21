# frozen_string_literal: true

# == Schema Information
#
# Table name: offer_options
#
#  id          :integer          not null, primary key
#  offer_id    :integer
#  product_id  :integer
#  recommended :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  option_type :string
#

require "rails_helper"

RSpec.describe OfferOption, type: :model do
  # Setup

  subject { offer_option }

  let(:offer_option) { build(:offer_option) }

  it { is_expected.to be_valid }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"

  # State Machine
  # Scopes
  # Associations

  it { expect(subject).to belong_to(:offer) }
  it { expect(subject).to belong_to(:product) }

  # Nested Attributes
  # Validations
  # Callbacks

  context "after_destroy" do
    it "deletes product when it is the price option" do
      offer_option = create(:price_option)
      expect { offer_option.destroy }.to change { Product.count }.by(-1)
    end

    it "deletes product when it is the cover option" do
      offer_option = create(:cover_option)
      expect { offer_option.destroy }.to change { Product.count }.by(-1)
    end

    it "deletes product when it is the cover&price option" do
      offer_option = create(:offer_option)
      expect { offer_option.destroy }.to change { Product.count }.by(-1)
    end

    it "does not delete product when it is the old product option" do
      offer_option = create(:old_product_option)
      expect { offer_option.destroy }.not_to(change { Product.count })
    end
  end

  # Instance Methods

  it { is_expected.to delegate_method(:yearly_premium).to(:product) }
  it { is_expected.to delegate_method(:plan_ident).to(:product) }
  it { is_expected.to delegate_method(:coverages).to(:product) }
  it { is_expected.to delegate_method(:premium_price).to(:product) }
  it { is_expected.to delegate_method(:premium_period).to(:product) }
  it { is_expected.to delegate_method(:contract_begin).to(:product).as(:contract_started_at) }

  # Class Methods

  context "factory methods" do
    let(:plan)    { create(:plan) }
    let(:offer)   { create(:offer) }
    let(:product) { create(:product) }

    before do
      allow(Product).to receive(:create_offered_product!).with(plan, Hash).and_return(product)
    end

    context "base creation method (private)" do
      let(:offer_option) do
        OfferOption.create_preconfigured_option!(
          plan: plan,
          offer: offer,
          option_type: :top_price
        )
      end

      it "creates a top price option" do
        expect(offer_option).to be_top_price
      end

      it "creates a top cover option" do
        offer_option_cover = OfferOption.create_preconfigured_option!(
          plan: plan,
          offer: offer,
          option_type: :top_cover
        )
        expect(offer_option_cover).to be_top_cover
      end

      it "creates a top cover and price option" do
        offer_option_cover_and_price = OfferOption.create_preconfigured_option!(
          plan: plan,
          offer: offer,
          option_type: :top_cover_and_price
        )
        expect(offer_option_cover_and_price).to be_top_cover_and_price
      end

      it "creates the product" do
        expect(offer_option.product).to eq(product)
      end

      it "connects the option to the offer" do
        expect(offer_option.offer).to eq(offer)
      end

      it "persists the option" do
        expect(offer_option).to be_persisted
      end

      it "allows to mark the option to be recommended" do
        recommended_offer_option = OfferOption.create_preconfigured_option!(
          plan: plan,
          offer: offer,
          option_type: :top_price,
          recommended: true
        )
        expect(recommended_offer_option.recommended).to be_truthy
      end
    end
  end
end
