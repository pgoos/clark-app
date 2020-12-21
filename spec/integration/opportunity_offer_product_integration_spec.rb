require 'rails_helper'

RSpec.describe 'Opportunity-Offer-Product integration', :integration, type: :integration do
  let!(:mandate) { create(:mandate) }
  let!(:user) { create(:user, mandate: mandate) }
  let!(:opportunity) { create(:opportunity, mandate: mandate) }

  context 'Opportunity in "initiation_phase"' do
    before do
      allow_any_instance_of(Offer).to receive(:vvg_attached_to_offer).and_return(true)
    end

    it 'moves opportunity into "offer_phase" when the offer is sent to the customer' do
      opportunity.update_attributes(state: 'initiation_phase')
      offer = create(:offer, state: 'in_creation', opportunity: opportunity, offer_options: [create(:price_option), create(:cover_option, recommended: true)])

      expect do
        offer.send_offer
        opportunity.reload
      end.to change { opportunity.state }.from('initiation_phase').to('offer_phase')
    end
  end

  context 'Opportunity in "offer_phase"' do
    let!(:offer) { create(:offer, state: 'active', opportunity: opportunity, mandate: mandate, offer_options: [create(:price_option), create(:cover_option, recommended: true)]) }
    before(:each) do
      opportunity.update_attributes(state: 'offer_phase')
    end

    context 'admin sets opportunity to lost' do
      it 'cancels the offer' do
        expect do
          opportunity.cancel
          offer.reload
        end.to change { offer.state }.from('active').to('canceled')
      end

      it 'cancels all offered products' do
        opportunity.cancel

        offer.offered_products.each do |product|
          expect(product).to be_canceled
        end
      end
    end

    context 'offer expires' do
      it 'moves opportunity to "lost"' do
        expect do
          offer.expire
          opportunity.reload
        end.to change { offer.state }.from('active').to('expired').and change { opportunity.state }.from('offer_phase').to('lost')
      end

      it 'cancels all offered products' do
        offer.expire

        offer.offered_products.each do |product|
          expect(product).to be_canceled
        end
      end

      it 'does not cancel old product' do
        old_product_option = create(:old_product_option, offer: offer)
        opportunity.update_attributes(old_product: old_product_option.product, category: old_product_option.product.category)

        offer.expire

        offer.offered_products.where(offer_options: { option_type: OfferOption.option_types[:old_product] }).each do |product|
          expect(product).to be_details_available
        end
      end
    end

    context 'offer is rejected' do
      let(:offer) { create(:offer, state: 'active', opportunity: opportunity, mandate: mandate, offer_options: [create(:price_option), create(:cover_option, recommended: true)]) }
      before(:each) do
        opportunity.update_attributes(state: 'offer_phase')
      end

      it 'moves opportunity to "lost"' do
        expect do
          offer.reject
          opportunity.reload
        end.to change { offer.state }.from('active').to('rejected').and change { opportunity.state }.from('offer_phase').to('lost')
      end

      it 'cancels all offered products' do
        offer.reject

        offer.offered_products.each do |product|
          expect(product).to be_canceled
        end
      end

      it 'does not cancel old product' do
        old_product_option = create(:old_product_option, offer: offer)
        opportunity.update_attributes(old_product: old_product_option.product, category: old_product_option.product.category)

        offer.reject

        offer.offered_products.where(offer_options: { option_type: OfferOption.option_types[:old_product] }).each do |product|
          expect(product).to be_details_available
        end
      end
    end

    context 'offer is accepted' do
      let(:offer) { create(:offer, state: 'active', opportunity: opportunity, mandate: mandate, offer_options: [create(:price_option), create(:cover_option, recommended: true)]) }
      let!(:chosen_product) { offer.offer_options.first.product }
      let!(:document) { create(:document, documentable: chosen_product, document_type: DocumentType.advisory_documentation) }

      before(:each) do
        opportunity.update_attributes(state: 'offer_phase')
      end

      it 'does not change the state of opportunity' do
        expect do
          offer.accept(chosen_product)
          opportunity.reload
        end.not_to change { opportunity.state }
      end

      it 'cancels offered products that were not chosen' do
        offer.accept(chosen_product)

        offer.offered_products.where.not(products: { id: chosen_product.id }).each do |product|
          expect(product).to be_canceled
        end
      end

      it 'sets the chosen offered product to "order_pending"' do
        expect do
          offer.accept(chosen_product)
          chosen_product.reload
        end.to change { chosen_product.state }.from('offered').to('order_pending')
      end

      it 'sets the mandate_id on the sold product' do
        expect do
          offer.accept(chosen_product)
          chosen_product.reload
        end.to change { chosen_product.mandate_id }.from(nil).to(mandate.id)
      end

      it 'sets the old product to "termination_pending"' do
        old_product_option = create(:old_product_option, offer: offer)
        offer.offer_options << old_product_option
        opportunity.update_attributes(old_product: old_product_option.product, category: old_product_option.product.category)

        expect do
          offer.accept(chosen_product)
          old_product_option.product.reload
        end.to change { old_product_option.product.state }.from('details_available').to('termination_pending')
      end
    end
  end

  context 'Product in order_pending state' do
    let!(:offer) do
      create(:offer, state: "active", opportunity: opportunity, mandate: mandate,
             offer_options: [create(:price_option),
                             create(:cover_option, recommended: true)])
    end
    let!(:chosen_product) { offer.offer_options.first.product }
    let!(:document) do
      create(:document, documentable: chosen_product, document_type: DocumentType.advisory_documentation)
    end

    before(:each) do
      opportunity.update_attributes(state: 'offer_phase')
      offer.accept!(chosen_product)
      chosen_product.reload
    end

    it 'moves opportunity to "completed"' do
      expect do
        chosen_product.order!
        opportunity.reload
      end.to change { opportunity.state }.from('offer_phase').to('completed')
    end

    it 'sets the correct sold product on the opportunity' do
      expect do
        chosen_product.order!
        opportunity.reload
      end.to change { opportunity.sold_product }.from(nil).to(chosen_product)
    end

    it 'sets the sold product even when opportunity is already finished' do
      opportunity.update_attributes(state: 'completed')

      expect do
        chosen_product.order!
        opportunity.reload
      end.to change { opportunity.sold_product }.from(nil).to(chosen_product)
    end

    it 'does not throw an exception opportunity is already finished' do
      opportunity.update_attributes(state: 'completed')

      expect do
        chosen_product.order!
      end.not_to raise_error
    end
  end

  context "offer with old product" do
    let!(:offer) do
      create(:offer, state: "active", opportunity: opportunity, mandate: mandate,
             offer_options: [create(:old_product_option), create(:price_option),
                             create(:cover_option, recommended: true)])
    end

    it 'does not delete the old product' do
      old_product = offer.old_product

      expect { offer.destroy }.to change { Offer.count }.by(-1).and change { OfferOption.count }.by(-3).and change { Product.count }.by(-2)
      expect { old_product.reload }.not_to raise_error
    end
  end

  context "deleting things" do
    let!(:offer) do
      create(:offer, state: "active", opportunity: opportunity, mandate: mandate,
             offer_options: [create(:price_option), create(:price_option),
                             create(:cover_option, recommended: true)])
    end

    it 'removes Opportunity, Offer, Offer Options, Products when Opportunity is destroyed' do
      expect { opportunity.destroy }.to change(Opportunity, :count).by(-1).and \
                                        change(Offer, :count).by(-1).and \
                                        change(OfferOption, :count).by(-3).and \
                                        change(Product, :count).by(-3)
    end

    it 'removes Offer, Offer Options, Products and nullifies offer_id on Opportunity when Offer is destroyed' do
      expect { offer.destroy }.to change(Opportunity, :count).by(0).and \
                                  change(Offer, :count).by(-1).and \
                                  change(OfferOption, :count).by(-3).and \
                                  change(Product, :count).by(-3)

      opportunity.reload
      expect(opportunity.offer).to be_nil
    end
  end
end
