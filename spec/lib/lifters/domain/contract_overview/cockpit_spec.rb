# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::Cockpit do
  subject { described_class.new(mandate) }

  let(:mandate) { create(:mandate) }
  let(:plan1) { create(:plan) }
  let(:plan2) { create(:plan) }
  let(:inquiry1) { create(:inquiry) }
  let(:inquiry2) { create(:inquiry) }
  let(:user_situation_class) { Domain::Situations::UserSituation }

  before do
    allow_any_instance_of(user_situation_class).to receive(:cockpit_score).with(no_args).and_return({})
    allow_any_instance_of(user_situation_class).to receive(:life_aspect_priorities).with(no_args)
  end

  context "mandate" do
    it "should delegate the score to the mandate" do
      expect(mandate).to receive(:score)
      subject.score
    end
  end

  context "user_situation" do
    describe "#life_aspect_score" do
      life_aspects = %i[health things retirement]

      let(:initial_life_aspect_value) { -> { {recommendations_count: 0, products_inquiries_count: 0} } }
      let(:initial_life_aspects) do
        life_aspects.each_with_object({}) { |key, result| result[key] = initial_life_aspect_value.() }
      end

      it "should delegate life_aspect_score to user_situation" do
        expect_any_instance_of(user_situation_class).to receive(:cockpit_score).with(no_args).and_return({})
        subject.life_aspect_score
      end

      it "should deliver the empty structure, if the life aspect score is empty" do
        expect(subject.life_aspect_score).to include(initial_life_aspects)
      end

      life_aspects.each do |life_aspect|
        it "should merge other aspects and deliver the empty structure for #{life_aspect}" do
          incomplete = {life_aspect => {recommendations_count: 1, products_inquiries_count: 1}}
          allow_any_instance_of(user_situation_class).to receive(:cockpit_score).with(no_args).and_return(incomplete)
          expect(subject.life_aspect_score).to include(initial_life_aspects.merge(incomplete))
        end
      end
    end

    it "should delegate life_aspect_priorities to user_situation" do
      expect_any_instance_of(user_situation_class).to receive(:life_aspect_priorities).with(no_args)
      subject.life_aspect_priorities
    end
  end

  context "associations" do
    before do
      create(:category, ident: "4fb3e303")
      create(:category, ident: "3659e48a")
      create(:bu_category)
    end

    context "#inquries" do
      before do
        inquiry1.inquiry_categories << create(:inquiry_category)
        inquiry2.inquiry_categories << create(:inquiry_category)
        mandate.inquiries << inquiry1
        mandate.inquiries << inquiry2
      end

      it "should load the inquries just once" do
        expect(mandate).to receive(:inquiries).once.and_call_original
        subject.inquiries
      end

      it "should return the decorated inquries" do
        result = subject.inquiries
        expect(result.size).to eq mandate.inquiries.size
        expect(result.first).to be_kind_of Domain::ContractOverview::Inquiry
        expect(result.map(&:id)).to match_array(mandate.inquiries.map(&:id))
      end

      context "#inquiry_categories" do
        it "should load the inquiry categories, unless cancelled by the customer" do
          included_entities = mandate.inquiries.map(&:inquiry_categories).flatten

          inquiry2.inquiry_categories << create(
            :inquiry_category,
            cancellation_cause: :cancelled_by_customer,
            deleted_by_customer: true
          )

          expect(subject.inquiry_categories).to contain_exactly(*included_entities)
        end
      end

      context "when inquiry has product created" do
        let(:inquiry) { create :inquiry, mandate: mandate }
        let!(:inquiry_category1) { create :inquiry_category, inquiry: inquiry }
        let!(:inquiry_category2) { create :inquiry_category, inquiry: inquiry }

        context "when not all inquiry categories are fulfilled with the products" do
          before do
            create :product,
                   :details_available,
                   mandate: mandate,
                   inquiry: inquiry,
                   category: inquiry_category1.category
          end

          it "includes the inquiry" do
            expect(subject.inquiries).to include inquiry
          end
        end
      end
    end

    context "#opportunities" do
      before do
        mandate.opportunities << create(:opportunity_with_offer, mandate: mandate)
        mandate.opportunities << create(:opportunity_with_offer, mandate: mandate)
      end

      it "should load the opportunitites just once", :integration do
        expect(mandate).to receive(:opportunities).once.and_call_original
        subject.opportunities
      end

      it "should return the opportunities", :integration do
        result = subject.opportunities
        expect(result).to match_array(mandate.opportunities)
      end

      context "when opportunity does not have an offer" do
        it "includes the opportunity", :integration do
          opportunity = create :opportunity, :offer_phase, mandate: mandate
          expect(subject.opportunities).to include opportunity
        end
      end

      context "when opportunity has inactive offer" do
        it "does not include the opportunity", :integration do
          offer = create :offer, :in_creation, mandate: mandate
          opportunity = create :opportunity, :offer_phase, mandate: mandate, offer: offer
          expect(subject.opportunities).not_to include opportunity
        end
      end
    end

    context "#offers" do
      before do
        mandate.opportunities << create(:opportunity_with_offer, mandate: mandate)
        mandate.opportunities << create(:opportunity_with_offer, mandate: mandate)
      end

      it "should load the offers just once", :integration do
        expect(mandate).to receive(:offers).once.and_call_original
        subject.offers
      end

      it "should return the proper amount of offers", :integration do
        expect(subject.offers.count).to eq(2)
      end

      it "should return the offers", :integration do
        result = subject.offers
        expect(result).to match_array(mandate.offers)
      end

      context "offer not active" do
        it "does not show an offer, that is still in creation", :integration do
          in_creation = create(:opportunity_with_offer_in_creation, mandate: mandate)
          mandate.opportunities << in_creation
          expect(subject.offers.map(&:id)).not_to include(in_creation.offer.id)
        end

        it "does not show an offer, that expired", :integration do
          expired = create(:opportunity_with_expired_offer, mandate: mandate)
          mandate.opportunities << expired
          expect(subject.offers.map(&:id)).not_to include(expired.offer.id)
        end
      end
    end

    context "#products" do
      before do
        mandate.products << (@product1 = create(:product, plan: plan1))
        mandate.products << (@product2 = create(:product, plan: plan2))
        mandate.products << create(:product, :retirement_equity_product)
      end

      it "should return the products" do
        result = subject.products
        expect(result.count).to be > 0
        expect(result).to match_array [@product1, @product2]
      end
    end

    context "#recommendations" do
      let(:recomm_state_class) { Domain::Recommendations::RecommendationState }

      before do
        mandate.recommendations << create(:recommendation, category: plan1.category)
        mandate.recommendations << create(:recommendation, category: plan2.category)
      end

      it "should load the recommendations just once" do
        expect(mandate).to receive(:recommendations).once.and_call_original
        subject.recommendations
      end

      it "should return the recommendation as states" do
        result = subject.recommendations.map(&:class).uniq
        expect(result).to include(recomm_state_class)
        expect(result.count).to eq(1)
      end

      it "should return the recommendation all recommendations as states" do
        result             = subject.recommendations.map(&:id).sort
        expected           = mandate.recommendations.map(&:id).sort
        expect(result).to match_array(expected)
      end
    end
  end

  describe "aggregated values" do
    let(:products) do
      [
        build_stubbed(:product, premium_price: 100, premium_period: "month"),
        build_stubbed(:product, premium_price: 216, premium_period: "year"),
        build_stubbed(:product, premium_price: 500, premium_period: "once")
      ]
    end

    before do
      repo = object_double Domain::ContractOverview::ProductsRepository.new, all: products
      allow(Domain::ContractOverview::ProductsRepository).to receive(:new).and_return repo
    end

    it "#products_yearly_total" do
      expect(subject.products_yearly_total).to be_a Money
      expect(subject.products_yearly_total.to_i).to eq 1416
    end

    it "#products_monthly_total" do
      expect(subject.products_monthly_total).to be_a Money
      expect(subject.products_monthly_total.to_i).to eq 118
    end
  end
end
