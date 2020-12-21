# == Schema Information
#
# Table name: document_types
#
#  id          :integer          not null, primary key
#  name        :string
#  key         :string
#  template    :string
#  description :string
#  extension   :string           default("pdf")
#

FactoryBot.define do
  factory :document_type do
    sequence(:key)         { |n| "Key##{n}" }
    sequence(:name)        { |n| "PDF##{n}" }
    sequence(:description) { |n| "Desription of document #{n}" }
  end

  trait :product_application_for_signing do
    key { "product_application_for_signing" }
    name { "Product application for signing" }
    description { "Product application for signing" }
  end

  trait :additional_product_application_for_signing do
    key { "additional_product_application_for_signing" }
    name { "Additional product application for signing" }
    description { "Additional product application for signing" }
  end

  trait :general_insurance_conditions do
    key { "general_insurance_conditions" }
    name { "General insurance conditions" }
    description { "General insurance conditions" }
  end

  trait :general_insurance_conditions_notification do
    key { "general_insurance_conditions_notification" }
    name { "Allgemeine Versicherungsbedingungen" }
    description { "Allgemeine Versicherungsbedingungen " }
  end

  trait :product_application_fully_signed do
    key { "product_application_fully_signed" }
    name { "Product application fully signed" }
    description { "Product application fully signed" }
  end

  trait :no_product_can_be_created do
    key { "no_product_can_be_created" }
    name { "no_product_can_be_created" }
    description { "Dein Foto-Upload" }
  end

  trait :num_one_reccommendation_day_two do
    key { "num_one_reccommendation_day_two" }
    name { "num_one_reccommendation_day_two" }
    description { "num_one_reccommendation_day_two" }
  end

  trait :num_one_reccommendation_day_one do
    key { "num_one_reccommendation_day_one" }
    name { "num_one_reccommendation_day_one" }
    description { "num_one_reccommendation_day_one" }
  end

  trait :fonds_finanz_accounting_report do
    key { "fonds_finanz_accounting_report" }
    name { "fonds_finanz_accounting_report" }
    description { "num_one_reccommendation_day_one" }
  end

  trait :visible_to_mandate_customer do
    authorized_customer_states { ["mandate_customer"] }
  end

  trait :visible_to_prospect_customer do
    authorized_customer_states { ["prospect"] }
  end

  trait :visible_to_self_service_customer do
    authorized_customer_states { ["self_service"] }
  end
end
