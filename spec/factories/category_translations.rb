# frozen_string_literal: true

FactoryBot.define do
  factory :category_translation, class: "Category::Translation" do
    name { "Translated Category Name" }
    locale { "de" }

    association :translated_model, factory: :category

    after(:create) do |translation|
      translation.translated_model.reload
    end
  end
end
