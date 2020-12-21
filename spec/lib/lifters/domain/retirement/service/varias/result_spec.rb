# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Service::Varias::Result do
  subject { described_class.new(code, body) }

  describe "#call" do
    context "when code is '200'" do
      let(:code) { "200" }

      context "when body is parsable" do
        let(:body) { "{}" }

        it "returns success" do
          expect(subject.call).to be_success
        end

        it "parses result" do
          expect(subject.call.result).to eq({})
        end
      end

      context "when body isn't parsable" do
        let(:body) { "not_json" }

        it "returns failure" do
          expect(subject.call).to be_failure
        end

        it "assigns unparsable body as an error" do
          expect(subject.call.errors).to contain_exactly(
            { unparsable: body }
          )
        end
      end
    end

    context "when code is '400'" do
      let(:code) { "400" }

      context "when body is parsable" do
        let(:body) { "{}" }

        it "returns failure" do
          expect(subject.call).to be_failure
        end

        it "parses errors" do
          expect(subject.call.errors).to contain_exactly({})
        end
      end

      context "when body isn't parsable" do
        let(:body) { "not_json" }

        it "returns failure" do
          expect(subject.call).to be_failure
        end

        it "assigns unparsable body as an error" do
          expect(subject.call.errors).to contain_exactly(
            { unparsable: body }
          )
        end
      end
    end
  end
end
