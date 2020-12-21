# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/interactors/compare_mapping"

RSpec.describe Carrier::Constituents::Arisecur::Interactors::CompareMapping, :integration do
  subject { described_class.new }

  let(:category_mapper) { instance_double(Carrier::Constituents::Arisecur::Mappers::CategoryMapper) }
  let(:get_categories_request) do
    instance_double(Carrier::Constituents::Arisecur::Outbound::Requests::GetCompanies, call: true)
  end
  let(:company_mapper) { instance_double(Carrier::Constituents::Arisecur::Mappers::CompanyMapper) }
  let(:get_companies_request) do
    instance_double(Carrier::Constituents::Arisecur::Outbound::Requests::GetCompanies, call: true)
  end

  before do
    allow(Carrier::Constituents::Arisecur::Outbound::Requests::GetCategories)
      .to receive(:new).and_return(get_categories_request)
    allow(Carrier::Constituents::Arisecur::Outbound::Requests::GetCompanies)
      .to receive(:new).and_return(get_companies_request)
    allow(Carrier::Constituents::Arisecur::Mappers::CategoryMapper)
      .to receive(:new).and_return(category_mapper)
    allow(Carrier::Constituents::Arisecur::Mappers::CompanyMapper)
      .to receive(:new).and_return(company_mapper)
  end

  context "companies" do
    context "when request is successful" do
      before do
        allow(get_companies_request).to receive_messages(
          response_body: [{ "Text" => "Test Arisecur", "Value" => "testarisecur" }],
          response_successful?: true
        )
        allow(get_categories_request).to receive_messages(
          response_body: [{ "Text" => "Test Arisecur", "Value" => "testarisecur" }],
          response_successful?: true
        )
      end

      context "when mapping matches" do
        before do
          allow(company_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName": "Test Clark",
                          "clarkIdent": "testclark",
                          "arisecurName": "Test Arisecur",
                          "arisecurIdent": "testarisecur"
                        }])
          allow(category_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName": "Test Clark",
                          "clarkIdent": "testclark",
                          "arisecurName": "Test Arisecur",
                          "arisecurIdent": "testarisecur"
                        }])
        end

        it "returns success true" do
          result = subject.call
          expect(result).to be_successful
          expect(result.errors).to be_empty
        end
      end

      context "when mapping does not match" do
        before do
          allow(company_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName" => "Test Clark",
                          "clarkIdent" => "testclark",
                          "arisecurName" => "Test Arisecur",
                          "arisecurIdent" => "testarisecur2"
                        }])
          allow(category_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName" => "Test Clark",
                          "clarkIdent" => "testclark",
                          "arisecurName" => "Test Arisecur",
                          "arisecurIdent" => "testarisecur"
                        }])
          # rubocop:disable Layout/LineLength
          allow(Carrier::Constituents::Arisecur::Outbound::Notifier).to receive(:notify_about_mapping).with(["Test Clark"])
          # rubocop:enable Layout/LineLength
        end

        it "calling Notifier with notify_about_mapping" do
          subject.call
        end
      end
    end
  end

  context "categories" do
    context "when request is successful" do
      before do
        allow(get_companies_request).to receive_messages(
          response_body: [{ "Text" => "Test Arisecur", "Value" => "testarisecur" }],
          response_successful?: true
        )
        allow(get_categories_request).to receive_messages(
          response_body: [{ "Text" => "Test Arisecur", "Value" => "testarisecur" }],
          response_successful?: true
        )
      end

      context "when mapping matches" do
        before do
          allow(company_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName" => "Test Clark",
                          "clarkIdent" => "testclark",
                          "arisecurName" => "Test Arisecur",
                          "arisecurIdent" => "testarisecur"
                        }])
          allow(category_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName" => "Test Clark",
                          "clarkIdent" => "testclark",
                          "arisecurName" => "Test Arisecur",
                          "arisecurIdent" => "testarisecur"
                        }])
        end

        it "returns success true" do
          result = subject.call
          expect(result).to be_successful
          expect(result.errors).to be_empty
        end
      end

      context "when mapping does not match" do
        before do
          allow(company_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName" => "Test Clark",
                          "clarkIdent" => "testclark",
                          "arisecurName" => "Test Arisecur",
                          "arisecurIdent" => "testarisecur"
                        }])
          allow(category_mapper)
            .to receive(:content)
            .and_return([{
                          "clarkName" => "Test Clark",
                          "clarkIdent" => "testclark",
                          "arisecurName" => "Test Arisecur",
                          "arisecurIdent" => "testarisecur2"
                        }])
          # rubocop:disable Layout/LineLength
          allow(Carrier::Constituents::Arisecur::Outbound::Notifier).to receive(:notify_about_mapping).with(["Test Clark"])
          # rubocop:enable Layout/LineLength
        end

        it "calling Notifier with notify_about_mapping" do
          subject.call
        end
      end
    end

    context "when request fails" do
      before do
        allow(get_companies_request).to receive(:response_successful?).and_return(true)
        allow(get_categories_request).to receive(:response_successful?).and_return(false)
      end

      it "returns error about problem with api" do
        result = subject.call
        expect(result).not_to be_successful
        expect(result.errors).to eq ["Problem with API categories request!"]
      end
    end
  end
end
