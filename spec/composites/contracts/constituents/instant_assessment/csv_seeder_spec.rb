# frozen_string_literal: true

require "composites/contracts/constituents/instant_assessment/csv_seeder"

require "rails_helper"

RSpec.describe Contracts::InstantAssessment::CSVSeeder do
  describe "#seed", :integration do
    context "validations" do
      context "when invalid file_type is passed in" do
        it "raise ArgumentError with message" do
          seeder = described_class.new(path: Rails.root.join("spec", "fixtures", "roles.yml"))

          expect { seeder.seed }.to raise_error(ArgumentError, "Invalid file format!")
        end
      end

      context "when non-existing file is passed in" do
        it "raise ArgumentError with message" do
          seeder = described_class.new(path: Rails.root.join("spec", "fixtures", "yolo.csv"))

          expect { seeder.seed }.to raise_error(ArgumentError, "File not found!")
        end
      end
    end

    context "when validations pass" do
      let!(:category) { create(:active_category, ident: "priv123", name: "Privathflicht") }
      let!(:company) { create(:company, :active, ident: "alli123", name: "Allianz") }
      let!(:another_company) { create(:company, :active, ident: "metlife123", name: "Metlife") }
      let(:valid_file) { Rails.root.join("spec", "fixtures", "instant_advice.csv") }
      let(:seeder) { described_class.new(path: valid_file) }
      let(:expected_schema) {
        {
          category_description: "Privathflicht is a necessary category.",
          popularity: {
            "value" => 83,
            "description" => "Allianz is popular among customers."
          },
          customer_review: {
            "value" => 78,
            "description" => "Customers rated this Contract very good."
          },
          claim_settlement: {
            "value" => 100,
            "description" => "Best claim settlement history."
          },
          price_level: {
            "value" => 100,
            "description" => "Cheapest Contract in this segment."
          },
          coverage_degree: {
            "value" => 95,
            "description" => "Covers wide variety of claims."
          },
          total_evaluation: {
            "value" => 90
          }
        }
      }

      before do
        Timecop.freeze(Time.local(2022))
      end

      after do
        Timecop.return
      end

      it "passing scenarios" do
        # seeder should log errors
        expect(seeder).to receive(:log).with("3", "missing_category").ordered.and_call_original
        expect(seeder).to receive(:log).with("4", "unknown_company").ordered.and_call_original
        expect(seeder).to receive(:log).with("5", "missing_category_description").ordered.and_call_original

        expect(seeder.seed).to be_truthy
        expect(::InstantAssessment.count).to eq(2)

        # count the number of successful and failed migrations
        expect(seeder.successfully_migrated).to eq(2)
        expect(seeder.failure_counter).to eq(3)

        advice = ::InstantAssessment.find_by(
          category_ident: category.ident,
          company_ident: company.ident
        )
        expect(advice).not_to be_nil

        # verify values are properly stored and text is interpolated
        expect(advice.category_description).to eq(expected_schema[:category_description])
        expect(advice.popularity).to eq(expected_schema[:popularity])
        expect(advice.customer_review).to eq(expected_schema[:customer_review])
        expect(advice.claim_settlement).to eq(expected_schema[:claim_settlement])
        expect(advice.price_level).to eq(expected_schema[:price_level])
        expect(advice.coverage_degree).to eq(expected_schema[:coverage_degree])
        expect(advice.total_evaluation).to eq(expected_schema[:total_evaluation])

        advice2 = ::InstantAssessment.find_by(
          category_ident: category.ident,
          company_ident: "metlife123"
        )
        expect(advice2).not_to be_nil
        # nil values should be accepted.
        expect(advice2.popularity["value"]).to be_nil
        expect(advice2.popularity["description"]).to be_nil

        # all decimal positions should be omitted and value should be an integer(eg. 83.123 -> 83)
        expect(advice2.customer_review["value"]).to eq(83)

        # make sure logs are persisted in file
        log_file_name = Rails.root.join("log", Time.current.strftime("instant-advice-seed-%FT%H%M%S.log"))
        file = File.open(log_file_name)
        expect(log_file_name.exist?).to be_truthy
        expect(file.readlines.count).to eq(5)
        file.close
      end
    end
  end
end
