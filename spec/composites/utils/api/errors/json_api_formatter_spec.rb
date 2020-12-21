# frozen_string_literal: true

require "spec_helper"
require "dry-struct"
require_relative "../../../../../config/initializers/dry_types"

require "composites/utils/api/errors/json_api_formatter"

RSpec.describe Utils::Api::Errors::JsonApiFormatter do
  let(:dummy_backtrace) { [] }

  describe "#call" do
    shared_examples "a formatter" do
      it "returns the expected JSON" do
        expect(described_class.call(parameter, dummy_backtrace)).to eq(expected_value)
      end
    end

    context "when it receives an string as message" do
      let(:parameter) { "Error" }
      let(:expected_value) do
        {
          errors: [
            { title: "Error" }
          ]
        }.to_json
      end

      it_behaves_like "a formatter"
    end

    context "when it receives an array as message" do
      let(:parameter) { %w[Error1 Error2] }
      let(:expected_value) do
        {
          errors: [
            { title: "Error1" },
            { title: "Error2" }
          ]
        }.to_json
      end

      it_behaves_like "a formatter"
    end

    context "when it receives a hash as message" do
      let(:parameter) { { email: "invalid email" } }
      let(:expected_value) do
        {
          errors: [
            { title: "invalid email", code: :email }
          ]
        }.to_json
      end

      it_behaves_like "a formatter"
    end

    context "when it receives an array of hash as message" do
      let(:parameter) do
        [
          { email: "invalid email" },
          { phone_number: "is not a German number" }
        ]
      end
      let(:expected_value) do
        {
          errors: [
            { meta: { data: { email: "invalid email" } } },
            { meta: { data: { phone_number: "is not a German number" } } }
          ]
        }.to_json
      end

      it_behaves_like "a formatter"
    end

    context "when it receives a ErrorObject" do
      let(:parameter) { Utils::Api::Errors::ErrorObject.new(title: "Error", source: { pointer: :email }) }
      let(:expected_value) do
        {
          errors: [
            { title: "Error", source: { pointer: "email" } }
          ]
        }.to_json
      end

      it_behaves_like "a formatter"
    end

    context "when it receives an array of ErrorObject" do
      let(:parameter) do
        [
          Utils::Api::Errors::ErrorObject.new(title: "Error 1", source: { pointer: :email }),
          Utils::Api::Errors::ErrorObject.new(title: "Error 2", source: { pointer: :phone_number })
        ]
      end
      let(:expected_value) do
        {
          errors: [
            { title: "Error 1", source: { pointer: "email" } },
            { title: "Error 2", source: { pointer: "phone_number" } }
          ]
        }.to_json
      end

      it_behaves_like "a formatter"
    end
  end
end
