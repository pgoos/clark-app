require 'rails_helper'

describe ProductPresenter, type: :presenter do

  context 'when the company is from gkv' do
    let(:product) { create(:product, premium_state: 'salary', premium_price: 0, plan: create(:plan, company: create(:gkv_company), category: create(:category_gkv))) }
    before do
      @product_presenter = ProductPresenter.new(product, view)
      @product_presenter.h.extend Manager::ProductsHelper
      @product_presenter.h.extend ApplicationHelper
    end

    describe '#policy_section?' do
      it 'returns false' do
        expect(@product_presenter.policy_section?).to eq(false)
      end
    end
  end

  context 'when the company is not from gkv' do
    let(:product) { create(:product, plan: create(:plan)) }

    before do
      @product_presenter = ProductPresenter.new(product, view)
      @product_presenter.h.extend Manager::ProductsHelper
      @product_presenter.h.extend ApplicationHelper
    end

    describe '#policy_section?' do
      it 'returns true' do
        expect(@product_presenter.policy_section?).to eq(true)
      end
    end

    context 'Offers' do
      it '#opportunity_in_offer_phase returns offer phase opportunity without offer' do
        opportunity = create(:opportunity, mandate: product.mandate, old_product: product, state: 'offer_phase', offer: nil)
        expect(@product_presenter.opportunity_in_offer_phase).to eq(opportunity)
      end

      it '#opportunity_in_offer_phase returns offer phase opportunity with an active offer' do
        offer = create(:offer, state: 'active')
        opportunity = create(:opportunity, mandate: product.mandate, old_product: product, state: 'offer_phase', offer: offer)
        expect(@product_presenter.opportunity_in_offer_phase).to eq(opportunity)
      end

      it '#opportunity_in_offer_phase returns nil for offer phase opportunity with an accepted offer' do
        offer = create(:offer, state: 'accepted')
        create(:opportunity, mandate: product.mandate, old_product: product, state: 'offer_phase', offer: offer)
        expect(@product_presenter.opportunity_in_offer_phase).to be_nil
      end

      it '#opportunity_in_offer_phase returns nil for offer phase opportunity with a rejected offer' do
        offer = create(:offer, state: 'rejected')
        create(:opportunity, mandate: product.mandate, old_product: product, state: 'offer_phase', offer: offer)
        expect(@product_presenter.opportunity_in_offer_phase).to be_nil
      end
    end
  end

  describe "#advised_quality" do
    subject(:presenter) { described_class.new product, double(:view) }

    let(:product) { build :product, :shallow }

    context "when good" do
      it { expect(presenter.advised_quality(:good)).to eq :good }
    end

    context "when bad" do
      it { expect(presenter.advised_quality(:bad)).to eq :bad }
    end

    context "when unknown" do
      it { expect(presenter.advised_quality(:unknown)).to eq nil }
    end
  end
end
