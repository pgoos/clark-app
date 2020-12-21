# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaire_questions
#
#  id                  :integer          not null, primary key
#  type                :string
#  profile_property_id :integer
#  question_text       :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  value_type          :string
#  question_identifier :string
#  description         :text
#  required            :boolean
#  question_type       :string
#  metadata            :jsonb
#

FactoryBot.define do
  factory :questionnaire_question, class: "Questionnaire::TypeformQuestion" do
    question_text { "Wie wohnst du?" }
    value_type { "Text" }
    question_identifier { "list_8645783" }
    description { "" }
    question_type { "text" }
  end

  factory :typeform_question, class: "Questionnaire::TypeformQuestion" do
    question_text { "Wie wohnst du?" }
    value_type { "Text" }
    question_identifier { "list_8645783" }
    description { "" }
    question_type { "text" }

    factory :questionnaire_typeform_question # Alias to match rails semantics
  end

  factory :custom_question, class: "Questionnaire::CustomQuestion" do
    question_text { "Wie wohnst du?" }
    value_type { "Text" }
    sequence(:question_identifier) { |n| "frage_#{n}" }
    description { "" }
    question_type { "text" }
    metadata { {'text': {multiline: false}} }

    factory :questionnaire_custom_question # Alias to match rails semantics
  end

  factory :multiple_choice_question, class: "Questionnaire::CustomQuestion" do
    question_text { "Wie wohnst du?" }
    value_type { "Text" }
    sequence(:question_identifier) { |n| "frage_#{n}" }
    description { "" }
    question_type { "multiple-choice" }
    metadata {
      {'multiple-choice': {multiple: false, choices: [
        {label: "ledig", value: "not_married", selected: true},
        {label: "verheiratet", value: "married", selected: false},
        {label: "geschieden", value: "divorced", selected: false}
      ]}}
    }

    factory :questionnaire_multiple_choice_question # Alias to match rails semantics
  end

  factory :multiple_choice_question_multiple, class: "Questionnaire::CustomQuestion" do
    question_text { "Welche Musik hörst Du?" }
    value_type { "Text" }
    sequence(:question_identifier) { |n| "frage_#{n}" }
    description { "" }
    question_type { "multiple-choice" }
    metadata {
      {'multiple-choice': {multiple: true, choices: [
        {label: "Jazz", value: "Jazz", selected: false},
        {label: "Funk", value: "Funk", selected: false},
        {label: "Speed Metal", value: "Speed Metal", selected: false}
      ]}}
    }
  end

  factory :free_text_question, class: "Questionnaire::CustomQuestion" do
    question_text { "Do you wanna say something to clark?" }
    value_type { "Text" }
    sequence(:question_identifier) { |n| "frage_#{n}" }
    description { "If you have any suggestions or feedback, now is the perfect opportunity" }
    question_type { "text" }
    metadata { {'text': {multiline: false}} }
    required { false }

    factory :questionnaire_free_text_question # Alias to match rails semantics
  end

  factory :date_question, class: "Questionnaire::CustomQuestion" do
    question_text { "When were you born?" }
    value_type { "Text" }
    sequence(:question_identifier) { |n| "frage_#{n}" }
    description { "Its the day when your mother gave birth to you!" }
    question_type { "date" }
    metadata { {'date': {}} }
    required { false }

    factory :questionnaire_date_question # Alias to match rails semantics
  end

  factory :multiple_choice_question_custom, class: "Questionnaire::CustomQuestion" do
    question_text { "What sort of music do you enjoy?" }
    value_type { "Text" }
    sequence(:question_identifier) { |n| "frage_#{n}" }
    description { "You can select the genere of music which you enjoy the most" }
    required { false }
    question_type { "multiple-choice" }
    metadata {
      {'multiple-choice': {multiple: false, choices: [
        {label: "Alternative", value: "alternative_value", selected: false},
        {label: "Blues", value: "blues_value", selected: false},
        {label: "Country", value: "country_value", selected: false},
        {label: "Electronic", value: "electronic_value", selected: false},
        {label: "Metal", value: "metal_value", selected: false}
      ]}}
    }

    factory :questionnaire_multiple_choice_question_custom # Alias to match rails semantics
  end

  factory :multiple_choice_jump_question_custom, class: "Questionnaire::CustomQuestion" do
    question_text { "What sort of music do you enjoy?" }
    value_type { "Text" }
    sequence(:question_identifier) { |n| "frage_#{n}" }
    description { "You can select the genere of music which you enjoy the most" }
    required { true }
    question_type { "multiple-choice" }
    metadata {
      {"jumps": [{"conditions": [{"field": "jq_1", "value": "Yes"}], "destination": {"id": "jq_3"}}],
       'multiple-choice': {multiple: false, choices: [
         {label: "Yes", value: "Yes", selected: false},
         {label: "No", value: "No", selected: false}
       ]}}
    }

    factory :questionnaire_multiple_choice_jump_question_custom # Alias to match rails semantics
  end
end
