# frozen_string_literal: true

require "spec_helper"
require "composites/contracts/constituents/instant_advice/repositories/instant_assessments_repository/evaluation_mapper"

RSpec.describe Contracts::Constituents::InstantAdvice::Repositories::InstantAssessmentsRepository::EvaluationMapper,
               :integration do
  describe "#entity_value" do
    let(:test_cases) do
      [
        { result: nil },
        { value: 1, description: Faker::Lorem.sentence, result: "Schlecht" },
        { value: 59, description: Faker::Lorem.sentence, result: "Schlecht" },
        { value: 60, description: Faker::Lorem.sentence, result: "Schwach" },
        { value: 69, description: Faker::Lorem.sentence, result: "Schwach" },
        { value: 70, description: Faker::Lorem.sentence, result: "Ordentlich" },
        { value: 81, description: Faker::Lorem.sentence, result: "Ordentlich" },
        { value: 82, description: Faker::Lorem.sentence, result: "Gut" },
        { value: 89, description: Faker::Lorem.sentence, result: "Gut" },
        { value: 90, description: Faker::Lorem.sentence, result: "Sehr gut" },
        { value: 100, description: Faker::Lorem.sentence, result: "Sehr gut" }
      ]
    end

    it "maps value properly" do
      test_cases.each do |test_case|
        expect(
          described_class.entity_value(
            value: test_case[:value],
            description: test_case[:description]
          )
        ).to eq(
          value: test_case[:result],
          description: test_case[:description]
        )
      end
    end
  end
end
