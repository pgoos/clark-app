# frozen_string_literal: true

FactoryBot.define do
  factory :marketing_cloud_import do
    after :build do |marketing_cloud_import|
      file_path = Rails.root.join("spec", "fixtures", "files", "tracking.csv")
      marketing_cloud_import.file.attach(
        io: File.open(file_path),
        filename: "tracking",
        content_type: "file/csv"
      )
    end

    trait :processed do
      processed_at { Time.parse("01/01/2020") }
    end
  end
end
