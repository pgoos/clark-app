# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id                :integer          not null, primary key
#  asset             :string
#  content_type      :string
#  size              :integer
#  documentable_id   :integer
#  documentable_type :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  document_type_id  :integer
#  metadata          :jsonb
#  qualitypool_id    :integer
#

FactoryBot.define do
  factory :document do
    association :documentable, factory: :mandate
    association :document_type, strategy: :build
    asset do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec", "support", "assets", "mandate.pdf"), "application/pdf"
      )
    end

    factory :shallow_document do
      shallow

      to_create { |opportunity| opportunity.save(validate: false) }
    end

    trait :shallow do
      documentable { nil }
    end

    trait :with_qualitypool_transfer do
      qualitypool_id { Faker::Number.number(digits: 5) }
    end

    trait :advisory_documentation do
      document_type { DocumentType.advisory_documentation }
    end

    trait :customer_upload do
      document_type { DocumentType.customer_upload }
    end

    trait :cover_note do
      document_type { DocumentType.deckungsnote }
    end

    trait :retirement_document do
      document_type { DocumentType.customer_upload }
      documentable_type { "Mandate" }
      association :documentable, factory: :mandate
      metadata { { "type_flag" => "retirement" } }
    end

    trait :satisfaction_document do
      document_type { DocumentType.satisfaction_email }
      documentable_type { "Mandate" }
      association :documentable, factory: :mandate
    end

    trait :mandate_document_biometric do
      document_type { DocumentType.mandate_document_biometric }
    end

    trait :with_customer_upload do
      document_type { DocumentType.customer_upload }
    end

    trait :greeting do
      document_type { DocumentType.greeting }
    end
  end
end
