require 'rails_helper'

RSpec.describe Platform::RuleEngineV3::Rules::OgRiester1 do
  let(:subject) { described_class }
  let(:category) { create(:category, ident: 'vorsorgeprivat') }
  let!(:questionnaire) do
    create(:questionnaire, category: category)
  end

  context 'engine' do
    context '.candidates' do
      let(:mandate_no_children) { create(:mandate) }
      let(:mandate_with_children) { create(:mandate) }
      let(:mandate_with_children_automated) { create(:mandate) }
      let(:mandate_with_children_adviced) { create(:mandate) }
      let(:mandate_with_product) { create(:mandate) }

      let(:bedarfscheck) { create(:bedarfscheck_questionnaire) }
      let(:kids_question) do
        create(:questionnaire_custom_question,
                           question_identifier: 'demand_kids')
      end
      let!(:admin) { create(:admin) }

      let(:category) { create(:category, ident: 'vorsorgeprivat') }
      let(:plan) { create(:plan, category: category) }
      let!(:product) do
        create(:product,
                           mandate: mandate_with_product,
                           plan: plan)
      end

      before(:each) do
        bedarfscheck.questions << kids_question
        bedarfscheck.save!

        demandcheck_with_children(mandate_with_children,
                                  kids_question, 'Ja')
        demandcheck_with_children(mandate_no_children,
                                  kids_question, 'Nein')
        demandcheck_with_children(mandate_with_children_automated,
                                  kids_question, 'Ja')
        demandcheck_with_children(mandate_with_children_adviced,
                                  kids_question, 'Ja')

        demandcheck_with_children(mandate_with_product,
                                  kids_question, 'Ja')

        Interaction.create(mandate: mandate_with_children_adviced)

        BusinessEvent.create!(action: 'automation_run',
                              metadata: { ident: 'OG_RIESTER_1' },
                              entity: mandate_with_children_automated,
                              audited_mandate: mandate_with_children_automated,
                              person: admin)
      end

      it 'selects the correct mandates' do
        expect(subject.mandates_with_products.count).to eq(1)

        expect(subject.candidates)
          .not_to include(mandate_no_children)
        expect(subject.candidates)
          .not_to include(mandate_with_children_automated)
        expect(subject.candidates)
          .not_to include(mandate_with_product)

        expect(subject.candidates).to include(mandate_with_children)

        # it includes it, but should not be applicable
        expect(subject.candidates).to include(mandate_with_children_adviced)
      end
    end
  end

  context 'rule' do
    context '#applicable' do
      before(:each) do
        allow_any_instance_of(subject)
          .to receive(:interacted_with_during_past_30_days).and_return(false)
      end

      it 'is applicable on accepted mandate' do
        mandate = n_double("mandate")
        allow(mandate).to receive(:accepted?).and_return(true)
        allow(mandate).to receive(:interactions)

        test_subject = subject.new(mandate: mandate, admin: double)
        expect(test_subject).to be_applicable
      end

      it 'is not applicable on non accepted' do
        mandate = n_double("mandate")
        allow(mandate).to receive(:accepted?).and_return(false)

        test_subject = subject.new(mandate: mandate, admin: double)
        expect(test_subject).not_to be_applicable
      end
    end

    context '#intent' do
      it 'returns an intent' do
        test_subject = subject.new(mandate: double, admin: double).intent
        expect(test_subject).to be_a(Platform::RuleEngineV3::Flows::MessageToQuestionnaire)
      end
    end
  end
end

def demandcheck_with_children(mandate, question, content)
  questionnaire_response = create(:questionnaire_response,
                                              questionnaire: bedarfscheck,
                                              mandate: mandate,
                                              state: 'analyzed')

  create(:questionnaire_answer,
                     question: question,
                     questionnaire_response: questionnaire_response,
                     answer: { text: content })
end
