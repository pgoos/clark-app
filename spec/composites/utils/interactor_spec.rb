# frozen_string_literal: true

require_relative "../../../config/initializers/dry_types"
require "composites/utils/interactor"

class DummyInteractor
  include Utils::Interactor

  def call(parameter)
    error!(parameter)
  end
end

RSpec.describe Utils::Interactor do
  let(:dummy) { DummyInteractor.new }

  describe "#error!" do
    context "when parameter is a Hash" do
      context "and it has title and source" do
        let(:parameter) { Hash[title: "Title", source: { pointer: "pointer" }] }

        it "adds a Utils::Api::Errors::ErrorObject to the errors list" do
          result = dummy.call(parameter)

          expect(result.errors.size).to be(1)
          expect(result.errors[0]).to be_kind_of(Utils::Api::Errors::ErrorObject)
        end
      end

      context "and does not have title or source" do
        it "does not add a Utils::Api::Errors::ErrorObject to the errors list" do
          parameter = { title: "Only title" }
          result = dummy.call(parameter)

          expect(result.errors.size).to be(1)
          expect(result.errors[0]).not_to be_kind_of(Utils::Api::Errors::ErrorObject)

          parameter = { source: { pointer: "Only source" } }
          result = dummy.call(parameter)

          expect(result.errors.size).to be(1)
          expect(result.errors[0]).not_to be_kind_of(Utils::Api::Errors::ErrorObject)
        end
      end
    end
  end
end
