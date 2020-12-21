require 'rails_helper'
require 'ostruct'

RSpec.describe Domain::OpportunityGeneration::OgKfzReminder1 do
  # System prerequisites
  let!(:admin) { create(:admin) }

  # Rule metadate
  let(:subject) { described_class }
  let(:expected_name) { 'OG_KFZ_REMINDER1' }
  let(:limit) {  }

  # Situation Specification
  let(:situation_class) { Domain::Situations::ProductSituation }
  let(:situation_expectations) do
    [
      :last_advice_is_acknowledged?,
    ]
  end

  # Candidate Specification
  let(:mandate) { create(:mandate, state: 'accepted', birthdate: 25.years.ago, gender: 'male') }

  let(:data_attribute) do
    {
      gender: mandate.gender,
      birthdate: mandate.birthdate.to_date.to_s,
      premium: ValueTypes::Money.new(110.00, 'EUR'),
      replacement_premium: ValueTypes::Money.new(89.00, 'EUR'),
      premium_period: :year,
      'VU' => 'tarif name', # TODO: Uses a param name specific to DA Direkt. Be generic instead.
    }
  end

  let!(:candidate) do
    product = create(:product,
                                 mandate: mandate,
                                 premium_price_cents: 11000,
                                 premium_price_currency: 'EUR',
                                 premium_period: :year)

    create(:advice, topic: product, acknowledged: false, mandate: mandate)
    create(:product_partner_datum,
                       state: 'chosen',
                       product: product,
                       data: data_attribute)
  end

  let(:candidates) do
    acknowledged_advice = RuleHelper.derive_candidate(
      OpenStruct.new,
      last_advice_is_acknowledged?: true,
      interacted_with_during_past_30_days: false,
    )

    unacknowledged_advice = RuleHelper.derive_candidate(
      OpenStruct.new,
      last_advice_is_acknowledged?: false,
      interacted_with_during_past_30_days: false,
    )

    already_recently_advised = RuleHelper.derive_candidate(
      OpenStruct.new,
      last_advice_is_acknowledged?: false,
      interacted_with_during_past_30_days: true,
    )

    {
      unacknowledged_advice => true,
      acknowledged_advice => false,
      already_recently_advised => false,
    }
  end

  # Intent to be played
  let(:intent_class) { Domain::Intents::PlayAdvice }
  let(:intent_options) { { candidate: candidate} }

  it_behaves_like 'v4 automation'
end
