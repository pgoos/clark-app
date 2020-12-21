# frozen_string_literal: true

require "rails_helper"

# TODO: Clean up this spec after executing this one time task in production
describe "rake one_shot:fix_instant_advice_text", type: :task do
  let!(:advice) { create(:instant_assessment, customer_review: customer_review, claim_settlement: claim_settlement) }

  context "when description texts are incorrect" do
    let(:customer_review) { { value: 1, description: "some text" } }
    let(:claim_settlement) { { value: 2, description: "Gründlichkeit, mit die ÖVB Schäden" } }

    it "fixes description text of customer_review and claim_settlement attributes" do
      task.invoke
      advice.reload
      expect(advice.customer_review["description"]).to eq("some text.")
      expect(advice.claim_settlement["description"]).to eq("Gründlichkeit, mit der die ÖVB Schäden")
    end
  end

  context "when description texts are correct" do
    let(:customer_review) { { value: 1, description: "some text." } }
    let(:claim_settlement) { { value: 2, description: "Gründlichkeit, mit der die ÖVB Schäden" } }

    it "acts as idempotent and changes nothing" do
      task.invoke
      advice.reload
      expect(advice.customer_review["description"]).to eq(customer_review[:description])
      expect(advice.claim_settlement["description"]).to eq(claim_settlement[:description])
    end
  end
end
