# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/exploration/repositories/questionnaire_response_repository"

RSpec.describe Customer::Constituents::Exploration::Repositories::QuestionnaireResponseRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#find_by_customer" do
    it "returns questionnaire_response with aggregated data" do
      mandate = create(:mandate)
      questionnaire_response = create(:questionnaire_response, mandate: mandate)

      result = repo.find_by_customer(mandate.id)
      expect(result).to be_kind_of Customer::Constituents::Exploration::Entities::QuestionnaireResponse
      expect(result.id).to eql(questionnaire_response.id)
    end

    context "when questionnaire_response does not exist" do
      it "returns nil" do
        expect(repo.find_by_customer(999)).to be_nil
      end
    end
  end
end
