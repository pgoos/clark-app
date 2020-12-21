# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_recognition, class: "OCR::Recognition" do
    trait :with_document_event do
      transient do
        document { association(:document) }
        inquiry_category { association(:inquiry_category) }
      end

      after(:create) do |ocr_recognition, evaluator|
        document = evaluator.document
        inquiry_category = evaluator.inquiry_category
        ocr_recognition.uploaded_document!(document, inquiry_category)
      end
    end

    trait :with_document_event_without_inquiry_category do
      transient do
        document { association(:document) }
      end

      after(:create) do |ocr_recognition, evaluator|
        document = evaluator.document
        ocr_recognition.uploaded_document!(document)
      end
    end

    trait :with_task_event do
      transient do
        task_id { "task_id" }
      end

      after(:create) do |ocr_recognition, evaluator|
        task_id = evaluator.task_id
        ocr_recognition.started_recognition!(task_id)
        ocr_recognition.update!(external_id: task_id)
      end
    end

    trait :with_product_validation_failed do
      transient do
        product_attributes { {number: "123456"} }
        ocr_payload { "ocr_payload" }
      end

      after(:create) do |ocr_recognition, evaluator|
        product_attributes = evaluator.product_attributes
        ocr_payload = evaluator.ocr_payload
        ocr_recognition.validated_product_with_errors!(product_attributes, ocr_payload: ocr_payload)
      end
    end

    trait :with_product_validation_succeded do
      transient do
        errors { ["Plan must be present"] }
        ocr_payload { "ocr_payload" }
      end

      after(:create) do |ocr_recognition, evaluator|
        errors = evaluator.errors
        ocr_payload = evaluator.ocr_payload
        ocr_recognition.validated_product_successfully!(errors, ocr_payload: ocr_payload)
      end
    end

    trait :with_product_creation do
      transient do
        product { build(:product) }
      end

      after(:create) do |ocr_recognition, evaluator|
        product = evaluator.product
        ocr_recognition.created_product_successfully!(product)
      end
    end
  end
end
