FactoryBot.define do

  factory :questionnaire_answer_empty, class: 'Questionnaire::Answer' do

  end

  factory :lp_questionnaire, class: 'Questionnaire' do
    questionnaire_type { 'typeform' }
    name { 'Our own Questionnaire' }
    description { 'Questionaire Description' }
    identifier { 'MMjgDL' }
  end

  factory :lp_question_for_whom, class: 'Questionnaire::CustomQuestion' do
    required { true }
    value_type { 'Text' }
    question_text { 'Für wen soll der Rechtsschutz gelten?' }
    question_identifier { 'list_35499520' }
  end

  factory :lp_questionnaire_answer_for_whom, class: 'Questionnaire::Answer' do
    question factory: :lp_question_for_whom
    question_text { 'Für wen soll der Rechtsschutz gelten?' }
    answer { { text: 'Für mich und meine Familie' } }
  end

  factory :lp_question_occupation, class: 'Questionnaire::CustomQuestion' do
    required { true }
    value_type { 'Text' }
    question_text { 'Wie ist dein beruflicher Status?' }
    question_identifier { 'list_35500184' }
  end

  factory :lp_questionnaire_answer_occupation, class: 'Questionnaire::Answer' do
    question factory: :lp_question_occupation
    question_text { 'Wie ist dein beruflicher Status?' }
    answer { { text: 'Angestellter' } }
  end

  factory :lp_question_coverage_area, class: 'Questionnaire::CustomQuestion' do
    required { true }
    value_type { 'Text' }
    question_text { 'Für welche Bereiche möchtest du Rechtsschutz haben?' }
    question_identifier { 'list_35501987' }
  end

  factory :lp_questionnaire_answer_coverage, class: 'Questionnaire::Answer' do
    question factory: :lp_question_coverage_area
    question_text { 'Für welche Bereiche möchtest du Rechtsschutz haben?' }
    answer { { text: 'Beruf, Verkehr, Wohnen' } }
  end

  factory :lp_question_deductible, class: 'Questionnaire::CustomQuestion' do
    required { true }
    value_type { 'Text' }
    question_text { 'Bist du bereit im Schadenfall einen Teil selbst zu zahlen?' }
    question_identifier { 'list_35502277' }
  end

  factory :lp_questionnaire_answer_deductible, class: 'Questionnaire::Answer' do
    question factory: :lp_question_deductible
    question_text { 'Bist du bereit im Schadenfall einen Teil selbst zu zahlen?' }
    answer { { text: 'Ja' } }
  end

  factory :lp_question_previous_claims, class: 'Questionnaire::CustomQuestion' do
    required { true }
    value_type { 'Text' }
    question_text { 'Wie viele Rechtsschutzfälle hast du bei anderen Versicherern in den letzten 5 Jahren geltend gemacht?' }
    question_identifier { 'list_35502393' }
  end

  factory :lp_questionnaire_answer_previous_claims, class: 'Questionnaire::Answer' do
    question factory: :lp_question_previous_claims
    question_text { 'Wie viele Rechtsschutzfälle hast du bei anderen Versicherern in den letzten 5 Jahren geltend gemacht?' }
    answer { { text: 'Keinen' } }
  end
end
