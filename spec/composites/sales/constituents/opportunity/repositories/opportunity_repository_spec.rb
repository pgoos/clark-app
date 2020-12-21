# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::OpportunityRepository, :integration do
  let(:repository) { described_class.new }

  describe "#create_opportunity!" do
    let(:mandate) { create(:mandate) }
    let(:category) { create(:category) }
    let(:sales_campaign) { create(:sales_campaign) }
    let(:source_description) { "welcome call" }

    context "when correct params are passed in" do
      let(:params) do
        {
          category_id: category.id,
          sales_campaign_id: sales_campaign.id,
          source_description: source_description
        }
      end

      it "creates Opportunity and returns object" do
        result = described_class.new.create_opportunity!(mandate.id, params)

        expect(result).to be_a(Sales::Constituents::Opportunity::Entities::Opportunity)
        expect(Opportunity.where(params.merge(mandate_id: mandate.id))).to exist
      end
    end

    context "when incorrect params are passed in" do
      it "rescue ActiveRecord error and throw Repository errors" do
        expect {
          described_class.new.create_opportunity!(mandate.id, category_id: 666)
        }.to raise_error(Utils::Repository::Errors::ValidationError)
      end
    end
  end

  describe "#update!" do
    context "when valid" do
      it "updates" do
        opportunity = create(:opportunity)
        customer_id = opportunity.mandate_id

        new_attributes = {
          previous_damages: "Something",
          preferred_insurance_start_date: "2020-06-24"
        }

        updated = repository.update!(customer_id, opportunity.id, new_attributes)

        opportunity.reload

        new_attributes.each do |key, value|
          attribute = opportunity.public_send(key)
          expect(attribute).to eq(value)
        end
      end
    end

    context "when invalid" do
      it "does not update" do
        opportunity = create(:opportunity)
        customer_id = opportunity.mandate_id

        new_attributes = {
          level: "not_listed"
        }

        updated = repository.update!(customer_id, opportunity.id, new_attributes)

        expect(updated).to be false

        opportunity.reload

        new_attributes.each do |key, value|
          attribute = opportunity.public_send(key)
          expect(attribute).not_to eq(value)
        end
      end
    end

    context "when mandate don't own the opportunity" do
      it "raises an error" do
        opportunity = create(:opportunity)
        customer_id = 1_000_110

        new_attributes = {
          previous_damages: "Something",
          preferred_insurance_start_date: "2020-06-24"
        }

        expect {
          repository.update!(customer_id, opportunity.id, new_attributes)
        }.to raise_error(Utils::Repository::Errors::Error)
      end
    end
  end

  describe "#accept_offer!" do
    let(:mandate) { create :mandate }

    context "when states are valid" do
      let(:opportunity) { create(:opportunity_with_offer, mandate: mandate, state: :offer_phase) }
      let(:accepted_product) { opportunity.offer.offer_options.first.product }

      let!(:document) do
        create(:document, document_type: DocumentType.advisory_documentation, documentable: accepted_product)
      end

      it "moved entities to the appropriate states" do
        repository.accept_offer!(opportunity.id, accepted_product.id)

        opportunity.reload
        offer_product_ids = opportunity.offer.offer_options.map(&:product_id)

        rejected_products =
          Product.where(id: offer_product_ids)
                 .where.not(id: accepted_product)

        # Opportunity moved to the 'completed' state
        expect(opportunity).not_to be_completed

        # Offer moved to the 'accepted' state
        expect(opportunity.offer).to be_accepted

        # Accepted Product moved to the 'order_pending' state
        expect(accepted_product.reload).to be_order_pending

        # Other Products moved to the 'canceled' state
        expect(rejected_products.map(&:state).uniq).to eq(%w[canceled])
      end
    end

    context "when offer is in 'in_creation' state" do
      let(:opportunity) { create(:opportunity_with_offer, mandate: mandate, state: :offer_phase) }
      let(:accepted_product) { opportunity.offer.offer_options.first.product }

      let!(:document) do
        create(:document, document_type: DocumentType.advisory_documentation, documentable: accepted_product)
      end

      before do
        opportunity.offer.update!(state: :in_creation)
      end

      it "raises invalid transition error for the offer and does not change the states" do
        expect { repository.accept_offer!(opportunity.id, accepted_product.id) }
          .to raise_error(StateMachines::InvalidTransition)

        opportunity.reload
        offer_product_ids = opportunity.offer.offer_options.map(&:product_id)
        offer_products = Product.where(id: offer_product_ids)

        # Opportunity haven't changed the state
        expect(opportunity).to be_offer_phase

        # Offer haven't changed the state
        expect(opportunity.offer).to be_in_creation

        # All offer Products haven't changed the states
        expect(offer_products.map(&:state).uniq).to eq(%w[offered])
      end
    end

    context "when accepted product is in 'details_available' state" do
      let(:opportunity) { create(:opportunity_with_offer, mandate: mandate, state: :offer_phase) }
      let(:accepted_product) { opportunity.offer.offer_options.first.product }

      let!(:document) do
        create(:document, document_type: DocumentType.advisory_documentation, documentable: accepted_product)
      end

      before do
        accepted_product.update!(state: :details_available)
      end

      it "raises invalid transition error for the product and does not change the states" do
        expect { repository.accept_offer!(opportunity.id, accepted_product.id) }
          .to raise_error(StateMachines::InvalidTransition)

        opportunity.reload
        offer_product_ids = opportunity.offer.offer_options.map(&:product_id)
        offer_products = Product.where(id: offer_product_ids)

        # Opportunity haven't changed the state
        expect(opportunity).to be_offer_phase

        # Offer haven't changed the state
        expect(opportunity.offer).to be_active

        # All offer Products haven't changed the states
        expect(offer_products.map(&:state).uniq.sort).to eq(%w[details_available offered])
      end
    end

    context "when low margin_level category" do
      let(:low_margin_category) { create(:category, :low_margin, simple_checkout: true) }

      let(:opportunity) do
        create(:opportunity_with_offer, mandate: mandate, state: :offer_phase, category: low_margin_category)
      end

      let!(:accepted_product) { opportunity.offer.offer_options.first.product }

      let!(:document) do
        create(:document, document_type: DocumentType.advisory_documentation, documentable: accepted_product)
      end

      it "triggers 'offer_thank_you' mailer" do
        expect(OfferMailer)
          .to receive(:offer_thank_you).and_return(ActionMailer::Base::NullMail.new)

        repository.accept_offer!(opportunity.id, accepted_product.id)
      end
    end

    context "when gkv category" do
      let!(:gkv_category) { create(:category_gkv, margin_level: "high", simple_checkout: true) }

      let!(:opportunity) do
        create(:opportunity_with_offer, mandate: mandate, state: :offer_phase, category: gkv_category)
      end

      let!(:accepted_product) { opportunity.offer.offer_options.first.product }

      let!(:document) do
        create(:document, document_type: DocumentType.advisory_documentation, documentable: accepted_product)
      end

      it "triggers 'offer_thank_you' mailer" do
        expect(OfferMailer)
          .to receive(:offer_thank_you).and_return(ActionMailer::Base::NullMail.new)

        repository.accept_offer!(opportunity.id, accepted_product.id)
      end
    end

    context "when high margin_level category" do
      let!(:high_margin_category) { create(:category, :high_margin, simple_checkout: true) }

      let!(:opportunity) do
        create(:opportunity_with_offer, mandate: mandate, state: :offer_phase, category: high_margin_category)
      end

      let!(:accepted_product) { opportunity.offer.offer_options.first.product }

      let!(:document) do
        create(:document, document_type: DocumentType.advisory_documentation, documentable: accepted_product)
      end

      it "should NOT trigger 'offer_thank_you' mailer" do
        expect(OfferMailer)
          .not_to receive(:offer_thank_you)

        repository.accept_offer!(opportunity.id, accepted_product.id)
      end
    end

    context "when medium margin_level category" do
      let!(:medium_margin_category) { create(:category, :medium_margin, simple_checkout: true) }

      let!(:opportunity) do
        create(:opportunity_with_offer, mandate: mandate, state: :offer_phase, category: medium_margin_category)
      end

      let!(:accepted_product) { opportunity.offer.offer_options.first.product }

      let!(:document) do
        create(:document, document_type: DocumentType.advisory_documentation, documentable: accepted_product)
      end

      it "should NOT trigger 'offer_thank_you' mailer" do
        expect(OfferMailer)
          .not_to receive(:offer_thank_you)

        repository.accept_offer!(opportunity.id, accepted_product.id)
      end
    end
  end

  describe "#find" do
    let(:mandate) { create(:mandate, :accepted) }

    context "when there is an opportunity" do
      it "returns that" do
        opportunity = create(
          :opportunity,
          mandate: mandate,
          previous_damages: "Something",
          preferred_insurance_start_date: Date.new(2021, 12, 6)
        )

        result = repository.find(mandate.id, opportunity.id)
        expect(result).to be_a(Sales::Constituents::Opportunity::Entities::Opportunity)
        expect(result.previous_damages).to eq("Something")
        expect(result.preferred_insurance_start_date.to_date).to eq(Date.new(2021, 12, 6))
      end
    end

    context "when there is no opportunity" do
      it "raise a not found error" do
        expect {
          repository.find(mandate.id, 1_000_000)
        }.to raise_error(Utils::Repository::Errors::NotFoundError)
      end
    end

    context "when opportunity belongs to someone else" do
      it "raise a not found error" do
        opportunity = create(
          :opportunity,
          previous_damages: "Something",
          preferred_insurance_start_date: Date.new(2021, 12, 6)
        )

        expect {
          repository.find(mandate.id, opportunity.id)
        }.to raise_error(Utils::Repository::Errors::NotFoundError)
      end
    end
  end
end
