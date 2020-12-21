# frozen_string_literal: true

require "rails_helper"

# TODO: WTF? parameter list is huge - Maybe on the future convert to an configuration object
RSpec.shared_examples "fact from question" do |description, method, question_id, value_type="Boolean", true_members=[ValueTypes::Boolean::TRUE], false_members=[ValueTypes::Boolean::FALSE], default=false|
  def build_question_with_value(question_id, value, value_type)
    question = create(
      :questionnaire_question, value_type: value_type,
      question_identifier: question_id, required: false
    )

    create(
      :questionnaire_answer, questionnaire_question_id: question.id,
      question_text: "What is the meaning of life?", answer: value,
      questionnaire_response: questionnaire_response
    )
  end

  it "true members and false members have no intersection" do
    expect(true_members - false_members).to match_array(true_members)
  end

  context description do
    it { expect(subject.send(method)).to eq(default) }

    {true: true_members, false: false_members}.each_pair do |key, members|
      members.each do |value|
        it "is #{key} for #{description} when #{value}" do
          build_question_with_value(question_id, value, value_type)
          expect(subject.send(method)).to eq(key == :true)
        end
      end
    end
  end
end

RSpec.describe Domain::Situations::UserSituation do
  let(:mandate)                  { create(:mandate) }
  let(:mandate_no_questionnaire) { create(:mandate) }
  let(:subject)                  { described_class.new(mandate) }
  let!(:phv)                     { create(:category, ident: "03b12732") }
  let(:questionnaire)            { create(:questionnaire, category: phv) }
  let(:questionnaire_response) do
    create(:questionnaire_response, mandate: mandate,
                       questionnaire: questionnaire, state: "completed")
  end

  context "incuded modules" do
    let(:modules) { described_class.included_modules }

    it { expect(modules).to include(Domain::Situations::AdviceSituation) }
    it { expect(modules).to include(Domain::Situations::UserProductSituation) }
  end

  context "#new" do
    it { expect { subject }.not_to raise_error }
  end

  context "#questionary?" do
    it "returns true if has a questionary" do
      questionnaire_response
      expect(subject.questionnaire?).to eq(true)
    end

    it { expect(described_class.new(mandate_no_questionnaire).questionnaire?).to eq(false) }
  end

  context "#address?" do
    it "returns true if has an address" do
      expect(subject.address?).to eq(true)
    end

    it "returns false if at least one of the address components is missing" do
      allow(subject.mandate).to receive(:address).and_return(nil)
      expect(subject.address?).to eq false
    end
  end

  context "#birthdate?" do
    it "returns true if has a birthdate" do
      expect(subject.birthdate?).to eq(true)
    end

    it "returns false if a birthdate isn't set" do
      mandate.birthdate = nil
      expect(subject.birthdate?).not_to eq(true)
    end
  end

  context "situations" do
    it_behaves_like "fact from question", "official (Beamter)", "official?", "list_12111610"
    it_behaves_like "fact from question",
                    "insure_rented_property (Mietsachschäden)",
                    "insure_rented_property?",
                    "list_12110966"
    it_behaves_like "fact from question",
                    "sailboat? (Segelboat)",
                    "sailboat?",
                    "list_12110970",
                    "int",
                    [4, 10, 15, 25].map { |i| ValueTypes::Int.new(i) },
                    [ValueTypes::Int.new(0)]
    it_behaves_like "fact from question",
                    "motorboat? (Motorboat)",
                    "motorboat?",
                    "list_12110971",
                    "int",
                    [5, 10, 15, -1].map { |i| ValueTypes::Int.new(i) },
                    [ValueTypes::Int.new(0)]
    it_behaves_like "fact from question",
                    "deductible (Selbstbeteiligung)",
                    "deductible?",
                    "list_12110965",
                    "Money",
                    [100, 250, 150, 200, 500, 300].map { |i| ValueTypes::Money.new(i, "EUR") },
                    [ValueTypes::Money.new(0, "EUR")]
    it_behaves_like "fact from question",
                    "observations",
                    "observations?",
                    "textarea_12110979",
                    "Text",
                    [ValueTypes::Text.new("client said something")],
                    []

    insured_losses = ValueTypes::InsuredLossCount.values

    insured_losses_low_risk = [ValueTypes::InsuredLossCount::NONE,
                               ValueTypes::InsuredLossCount::ONE]
    insured_losses_high_risk = insured_losses - insured_losses_low_risk
    it_behaves_like "fact from question",
                    "Insured Loss Risk (Haftpflichtschäden)",
                    "insured_losses_risk?",
                    "list_12111755",
                    "InsuredLossCount",
                    insured_losses_high_risk,
                    insured_losses_low_risk
    has_single_claim = [ValueTypes::InsuredLossCount::ONE]
    do_not_have_single_claim = insured_losses - insured_losses_low_risk
    it_behaves_like "fact from question",
                    "Has single claim (Haftpflichtschäden)",
                    "has_single_claim?",
                    "list_12111755",
                    "InsuredLossCount",
                    has_single_claim,
                    do_not_have_single_claim
    all_family_statuses = ValueTypes::FamilyStatus.values
    single = [ValueTypes::FamilyStatus::SINGLE]
    duo = [ValueTypes::FamilyStatus::PARTNER_OR_PAIR,
           ValueTypes::FamilyStatus::FAMILY_NO_CHILD]
    family = [ValueTypes::FamilyStatus::FAMILY_WITH_CHILD,
              ValueTypes::FamilyStatus::SINGLE_WITH_CHILD]
    all_family_statuses_but_single = all_family_statuses - single
    it_behaves_like "fact from question",
                    "Single Family",
                    "single?",
                    "list_12110962",
                    "FamilyStatus",
                    single,
                    all_family_statuses_but_single
    all_family_statuses_but_duo = all_family_statuses - duo
    it_behaves_like "fact from question",
                    "Duo",
                    "couple?",
                    "list_12110962",
                    "FamilyStatus",
                    duo,
                    all_family_statuses_but_duo
    all_family_statuses_but_family = all_family_statuses - family
    it_behaves_like "fact from question",
                    "Family",
                    "family?",
                    "list_12110962",
                    "FamilyStatus",
                    family,
                    all_family_statuses_but_family
    context "old_product_without_details?" do
      let(:opportunity) do
        create(:opportunity, mandate:     mandate,
                                         old_product: create(:product))
      end
      let(:opportunity_no_product) { create(:opportunity, mandate: mandate) }

      it { expect(subject.old_product_without_details?).to eq(false) }

      it "is false if opportunnity has no old produt" do
        subject = described_class.new(mandate, opportunity_no_product)

        expect(subject.old_product_without_details?).to eq(false)
      end

      it "is true if has old product and no details or not under management" do
        allow(opportunity.old_product).to receive(:details_available?).and_return(false)
        allow(opportunity.old_product).to receive(:under_management?).and_return(false)

        subject = described_class.new(mandate, opportunity)

        expect(subject.old_product_without_details?).to eq(true)
      end

      it "is false if has old product and have details" do
        expect(opportunity.old_product).to receive(:details_available?).and_return(true)
        allow(opportunity.old_product).to receive(:under_management?).and_return(false)

        subject = described_class.new(mandate, opportunity)

        expect(subject.old_product_without_details?).to eq(false)
      end

      it "is false if has old product and it is under management" do
        allow(opportunity.old_product).to receive(:details_available?).and_return(false)
        expect(opportunity.old_product).to receive(:under_management?).and_return(true)

        subject = described_class.new(mandate, opportunity)

        expect(subject.old_product_without_details?).to eq(false)
      end
    end
  end

  context "#get_selling_opportunities" do
    let!(:disability_insurance) { create(:category, ident: "3d439696") }
    let(:direct_insurance) { create(:category) }
    let(:pension_funds) { create(:category) }
    let!(:private_retirement_umbrella) do
      create(:category, ident:                 "vorsorgeprivat",
                                    category_type:         Category.category_types[:umbrella],
                                    included_category_ids: [direct_insurance.id, pension_funds.id])
    end

    it "returns a hash including the two selling opportunities that should be adviced" do
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities).to be_kind_of(Hash)
      expect(selling_opportunities.count).to eq(2)
    end

    it "sets the selling opportunity to not_yet state by default" do
      selling_opportunities = subject.get_selling_opportunities
      selling_opportunities.each_value do |val|
        expect(val).to eq(described_class::STATE_NOT_YET)
      end
    end

    it "sets the selling opportunity to open state if mandate has an open opportunity of that category" do
      create(:opportunity, mandate: mandate, category: disability_insurance)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[0]).to eq(described_class::STATE_OPEN)
    end

    it "sets the selling opportunity to lost state if mandate has an open opportunity of that category that was set to lost" do
      create(:opportunity, mandate: mandate, category: disability_insurance, state: :lost)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[0]).to eq(described_class::STATE_LOST)
    end

    it "sets the selling opportunity to has_already state if mandate has an open inquiry of that category" do
      create(:inquiry, mandate: mandate, categories: [disability_insurance])
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[0]).to eq(described_class::STATE_HAS_ALREADY)
    end

    it "does not set the selling opportunity to has_already state if mandate has a rejected inquiry of that category" do
      create(:inquiry, mandate: mandate, categories: [disability_insurance], state: :canceled)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[0]).to eq(described_class::STATE_NOT_YET)
    end

    it "sets the selling opportunity to has_already state if mandate has a product of that category" do
      create(:product, mandate: mandate, category: disability_insurance)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[0]).to eq(described_class::STATE_HAS_ALREADY)
    end

    it "does not set the selling opportunity to has_already state if mandate has a canceled product of that category" do
      create(:product, mandate: mandate, category: disability_insurance, state: :canceled)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[0]).to eq(described_class::STATE_NOT_YET)
    end

    it "sets the selling opportunity to lost state if mandate has a lost opportunity on one of the children of that umbrella category" do
      create(:opportunity, mandate: mandate, category: direct_insurance, state: :lost)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[1]).to eq(described_class::STATE_LOST)
    end

    it "overrides lost with open if a newer opportunity is open on a category while an older one is lost" do
      create(:opportunity, mandate: mandate, category: disability_insurance, state: :lost)
      create(:opportunity, mandate: mandate, category: disability_insurance)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[0]).to eq(described_class::STATE_OPEN)
    end

    it "overrides lost with open if an opportunity is open on a sub category while an older one is lost" do
      create(:opportunity, mandate: mandate, category: direct_insurance, state: :lost)
      create(:opportunity, mandate: mandate, category: direct_insurance)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[1]).to eq(described_class::STATE_OPEN)
    end

    it "overrides lost with open if an opportunity is open on a sub category while another is lost on another category" do
      create(:opportunity, mandate: mandate, category: direct_insurance, state: :lost)
      create(:opportunity, mandate: mandate, category: pension_funds)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[1]).to eq(described_class::STATE_OPEN)
    end

    it "overrides lost with open if an opportunity is lost on a sub category while another is open on the umbrella category" do
      create(:opportunity, mandate: mandate, category: direct_insurance, state: :lost)
      create(:opportunity, mandate: mandate, category: private_retirement_umbrella)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[1]).to eq(described_class::STATE_OPEN)
    end

    it "overrides open with has_already if an opportunity is open on a sub category while a product is available on another category" do
      create(:opportunity, mandate: mandate, category: direct_insurance, state: :lost)
      create(:product, mandate: mandate, category: pension_funds)
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[1]).to eq(described_class::STATE_HAS_ALREADY)
    end

    it "overrides open with has_already if an opportunity is open on a sub category while an open inquiry is available on another category" do
      create(:opportunity, mandate: mandate, category: direct_insurance, state: :lost)
      create(:inquiry, mandate: mandate, categories: [pension_funds])
      selling_opportunities = subject.get_selling_opportunities
      expect(selling_opportunities.values[1]).to eq(described_class::STATE_HAS_ALREADY)
    end
  end

  context "#welcome_call" do
    it "returns not_attempted as the status if no mandate welcome call found in the interactions" do
      expect(subject.welcome_call[:status]).to eq(:not_attempted)
    end

    it "returns nil as the interaction if no mandate welcome call found in the interactions" do
      expect(subject.welcome_call[:interaction]).to be_nil
    end

    it "returns successful if the last welcome call found in the interactions and was in reached state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
                         status: Interaction::PhoneCall::STATUS_REACHED, mandate: mandate)
      expect(subject.welcome_call[:status]).to eq(:successful)
    end

    it "returns the phone call as interaction entry if the last welcome call found in the interactions" do
      interaction = create(:interaction_phone_call,
                                       call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
                                       status:    Interaction::PhoneCall::STATUS_REACHED,
                                       mandate:   mandate)
      expect(subject.welcome_call[:interaction]).to eq(interaction)
    end

    it "returns unsuccessful if the last welcome call found in the interactions and was in not reached state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
                         status: Interaction::PhoneCall::STATUS_NOT_REACHED, mandate: mandate)
      expect(subject.welcome_call[:status]).to eq(:unsuccessful)
    end

    it "returns unsuccessful if the last welcome call found in the interactions and was in need follow up state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
                         status: Interaction::PhoneCall::STATUS_NEED_FOLLOW_UP, mandate: mandate)
      expect(subject.welcome_call[:status]).to eq(:unsuccessful)
    end

    it "returns successful if more than one welcome call found in the interactions and the last one was in reached state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
                         status: Interaction::PhoneCall::STATUS_NEED_FOLLOW_UP, mandate: mandate)
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:mandate_welcome],
                         status: Interaction::PhoneCall::STATUS_REACHED, mandate: mandate)
      expect(subject.welcome_call[:status]).to eq(:successful)
    end
  end

  context "#cockpit_score" do
    let(:health_category) { create(:category, life_aspect: :health) }
    let(:second_health_category) { create(:category, life_aspect: :health) }
    let(:things_category) { create(:category, life_aspect: :things) }
    let(:retirement_category) { create(:category, life_aspect: :retirement) }

    context "mandate did not complete demandcheck" do
      it "returns an empty hash always" do
        expect(subject.cockpit_score).to eq({})
      end
    end

    context "mandate finalized demandceck" do
      let(:mandate_with_recommendations) { create(:mandate) }
      let!(:health_recommendation) { create(:recommendation, mandate: mandate_with_recommendations, category: health_category) }
      let!(:second_health_recommendation) { create(:recommendation, mandate: mandate_with_recommendations, category: second_health_category) }
      let!(:things_recommendation) { create(:recommendation, mandate: mandate_with_recommendations, category: things_category) }
      let!(:retirement_recommendation) { create(:recommendation, mandate: mandate_with_recommendations, category: retirement_category) }

      before do
        allow(mandate_with_recommendations).to receive(:done_with_demandcheck?).and_return(true)
      end

      context "when recommendation dismissed" do
        it "is not taken into the response" do
          create(:recommendation, mandate: mandate_with_recommendations, dismissed: true)

          user_score = described_class.new(mandate_with_recommendations).cockpit_score
          expect(user_score[:health][:recommendations_count]).to eq(2)
          expect(user_score[:things][:recommendations_count]).to eq(1)
          expect(user_score[:retirement][:recommendations_count]).to eq(1)
        end
      end

      it "returns an empty hash if mandate has no recommendations" do
        mandate_no_recommendation = create(:mandate)
        allow(mandate_no_recommendation).to receive(:done_with_demandcheck?).and_return(true)
        expect(described_class.new(mandate_no_recommendation).cockpit_score).to eq({})
      end

      it "returns a hash with the life aspect as the key and recomendations count linked to this life aspect" do
        user_score = described_class.new(mandate_with_recommendations).cockpit_score
        expect(user_score[:health][:recommendations_count]).to eq(2)
        expect(user_score[:things][:recommendations_count]).to eq(1)
        expect(user_score[:retirement][:recommendations_count]).to eq(1)
      end

      context "products inquiries count" do
        it "increases the inquiries count mapped to a life spec if an active inquiry is found for a mandate recommendation" do
          create(:inquiry, mandate:    mandate_with_recommendations,
                                       categories: [health_category],
                                       state:      Inquiry::OPEN_INQUIRY_STATES.sample)
          user_score = described_class.new(mandate_with_recommendations).cockpit_score
          expect(user_score[:health][:products_inquiries_count]).to eq(1)
        end

        it "does not take into consideration inacitve inquiries in count mapped to a life spec" do
          create(:inquiry, mandate:    mandate_with_recommendations,
                                       categories: [health_category],
                                       state:      :canceled)
          user_score = described_class.new(mandate_with_recommendations).cockpit_score
          expect(user_score[:health][:products_inquiries_count]).to eq(0)
        end

        it "increases the products count mapped to a life spec if an active product is found for a mandate recommendation" do
          create(:product, mandate:  mandate_with_recommendations,
                                       category: health_category,
                                       state:    Product::STATES_OF_ACTIVE_PRODUCTS.sample)
          user_score = described_class.new(mandate_with_recommendations).cockpit_score
          expect(user_score[:health][:products_inquiries_count]).to eq(1)
        end

        it "does not take into consideration inacitve porducts in count mapped to a life spec" do
          create(:product, mandate:  mandate_with_recommendations,
                                       category: health_category,
                                       state:    :canceled)
          user_score = described_class.new(mandate_with_recommendations).cockpit_score
          expect(user_score[:health][:products_inquiries_count]).to eq(0)
        end

        it "increases the product count if a product with customer_provided state found for recommendation" do
          create(:product,
                 mandate: mandate_with_recommendations,
                 category: health_category,
                 state: :customer_provided)
          user_score = described_class.new(mandate_with_recommendations).cockpit_score
          expect(user_score[:health][:products_inquiries_count]).to eq(1)
        end
      end
    end
  end

  context "#has_open_opportunity_of_category?" do
    let(:category) { create(:category) }
    let(:category_no_opportunity) { create(:category) }
    let!(:opportunity) {
      create(:opportunity, mandate: mandate, category: category, state: :offer_phase)
    }

    it "returns true if mandate has an open opportunity on the category" do
      expect(subject.has_open_opportunity_of_category?(category)).to eq(true)
    end

    it "returns false if mandate has an opportunity on the category but not in open states" do
      opportunity.update_attributes(state: :lost)
      expect(subject.has_open_opportunity_of_category?(category)).to eq(false)
    end

    it "returns false if mandate has no opportunity on the category" do
      expect(subject.has_open_opportunity_of_category?(category_no_opportunity)).to eq(false)
    end
  end

  context "#has_rejected_offer_of_category?" do
    let(:category) { create(:category) }
    let(:category_no_opportunity) { create(:category) }
    let!(:opportunity) do
      create(:opportunity, mandate: mandate, category: category, state: :lost)
    end

    it "returns true if mandate has a lost opportunity on the category" do
      expect(subject.has_rejected_offer_of_category?(category)).to eq(true)
    end

    it "returns false if mandate has an opportunity on the category but in open states" do
      opportunity.update_attributes(state: :offer_phase)
      expect(subject.has_rejected_offer_of_category?(category)).to eq(false)
    end

    it "returns false if mandate has no opportunity on the category" do
      expect(subject.has_rejected_offer_of_category?(category_no_opportunity)).to eq(false)
    end
  end

  describe "#life_aspect_priorities" do
    it "defaults to a hash of life aspects with zero values if no answers are there" do
      default_priority_hash = {
        "health"     => 0,
        "retirement" => 0,
        "things"     => 0
      }
      expect(subject.life_aspect_priorities).to eq(default_priority_hash)
    end

    it "returns a hash of each life aspect with the priority if there is a user answer" do
      bedarfcheck_questionnaire = create(:bedarfscheck_questionnaire)
      questionnaire_response = create(:questionnaire_response,
                                                  mandate:       mandate,
                                                  questionnaire: bedarfcheck_questionnaire)
      health_priority = 2
      retirement_priority = 3
      things_priority = 1
      priority_hash = {
        "health"     => health_priority,
        "retirement" => retirement_priority,
        "things"     => things_priority
      }
      create_question_with_answer(:demand_priority_existence, health_priority, questionnaire_response)
      create_question_with_answer(:demand_priority_retirement, retirement_priority, questionnaire_response)
      create_question_with_answer(:demand_priority_things, things_priority, questionnaire_response)
      expect(subject.life_aspect_priorities).to eq(priority_hash)
    end

    context "when questionnaire_response has no questionnaire" do
      let(:questionnaire) { create(:questionnaire) }
      let!(:questionnaire_response) do
        create(:questionnaire_response, questionnaire: questionnaire, mandate: mandate)
      end

      before do
        questionnaire.destroy
      end

      it do
        expected_response = {"health" => 0, "retirement" => 0, "things" => 0}
        expect(subject.life_aspect_priorities).to eq expected_response
      end
    end
  end

  private

  def create_question_with_answer(question_ident, answer, questionnaire_response)
    question = create(:questionnaire_custom_question, question_identifier: question_ident)
    create(:questionnaire_answer, question: question, questionnaire_response: questionnaire_response, answer: {text: answer})
  end
end
