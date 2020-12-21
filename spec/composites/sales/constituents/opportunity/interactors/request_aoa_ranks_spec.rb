# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::RequestAoaRanks do
  let!(:open_opportunity_buckets) { [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140] }
  let!(:revenue_buckets) { [3000, 9000, 17_000, 23_000, 27_000, 33_000, 47_000, 53_000, 70_000] }
  let!(:admin) { create :admin, access_flags: %w[sales_consultation] }
  let(:expected_response_body) { { "allocated_consultants" => [admin.id] }.to_json }

  let(:body_with_error) do
    { "code" => 500, "description" => "Internal error.", "name" => "Internal Server Error" }.to_json
  end

  let(:aoa_request_headers) do
    { "X-Request-Id" => Faker::String.random }
  end

  let(:category_ident) { "ident" }

  let(:monthly_performance_response) do
    {
      admin.id => {
        consultant_id: Faker::Number.between(from: 5, to: 10),
        performance_matrix: fake_performance_matrix(0.5),
        performance_level: "a"
      }
    }
  end

  def fake_performance_matrix(conversion_rate)
    open_opportunity_buckets.each_with_object({}) do |row_bucket, result|
      result[row_bucket] = {}
      revenue_buckets.each do |col_bucket|
        result[row_bucket][col_bucket] = conversion_rate
      end
    end
  end

  before do
    allow_any_instance_of(
      Sales::Constituents::Opportunity::Repositories::MonthlyAdminPerformancesRepository
    ).to receive(:load_latest_performance_matrix_for).and_return(monthly_performance_response)

    allow_any_instance_of(Sales::Constituents::Opportunity::Repositories::AoaSettingsRepository)
      .to receive(:aoa_api_url).and_return("https://test-url.com/allocate_consultants")
  end

  context "successful request" do
    before do
      allow(Faraday).to receive(:post).and_return(
        OpenStruct.new(
          status: 201,
          body: expected_response_body,
          env: OpenStruct.new(request_headers: aoa_request_headers)
        )
      )
    end

    it "returns result" do
      result = subject.call(category_ident)
      expect(result).to be_kind_of Utils::Interactor::Result
    end

    it "successful" do
      result = subject.call(category_ident)
      expect(result).to be_successful
    end

    it "returns consultans rate" do
      result = subject.call(category_ident)
      expect(result.aoa_ranks).to eq(JSON.parse(expected_response_body)["allocated_consultants"])
      expect(result.request_uuid).to eq(aoa_request_headers["X-Request-Id"])
    end

    context "error in the body" do
      before do
        allow(Faraday).to receive(:post).and_return(
          OpenStruct.new(
            status: 201,
            body: body_with_error,
            env: OpenStruct.new(request_headers: aoa_request_headers)
          )
        )
      end

      it "not successful" do
        result = subject.call(category_ident)
        expect(result).not_to be_successful
      end

      it "does not return consultans rate" do
        result = subject.call(category_ident)

        expect(result.aoa_ranks).to eq([])
        expect(result.request_uuid).to eq(aoa_request_headers["X-Request-Id"])
      end

      it "expects to include the error message" do
        result = subject.call(category_ident)

        expect(result.errors).not_to be_empty
        expect(result.request_uuid).to eq(aoa_request_headers["X-Request-Id"])
      end
    end
  end

  context "failed request" do
    before do
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
    end

    it "returns result" do
      result = subject.call(category_ident)
      expect(result).to be_kind_of Utils::Interactor::Result
    end

    it "not successful" do
      result = subject.call(category_ident)
      expect(result).not_to be_successful
    end

    it "does not return consultans rate" do
      result = subject.call(category_ident)

      expect(result.aoa_ranks).to eq([])
    end

    it "expects to include the error message" do
      result = subject.call(category_ident)

      expect(result.errors).not_to be_empty
    end
  end

  context "passing a block" do
    it "executes passed block" do
      logger = double("logger", result: true)
      expect(logger).to receive(:result)
      subject.call(category_ident) { logger.result }
    end
  end
end
