# frozen_string_literal: true

FactoryBot.define do
  factory :ops_report do
    after :build do |report|
      file_path = Rails.root.join("spec", "fixtures", "files", "sample_ops_report.csv")
      report.file.attach(io: File.open(file_path), filename: "report", content_type: "file/csv")
    end
  end
end
