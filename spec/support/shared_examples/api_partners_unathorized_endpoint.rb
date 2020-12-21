# frozen_string_literal: true

RSpec.shared_examples "unathorized endpoint of the partnership api" do |url|
  context "when unauthorized" do
    before do
      partners_post url || endpoint
    end

    it "returns 401" do
      expect(response.status).to eq(401)
    end

    it "returns the error object" do
      expect(response.body).to match_response_schema("partners/20170213/error")
    end
  end
end
