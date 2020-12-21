# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DemandCheck::DemandCheckHelper do
  let(:mandate) { create(:mandate, :accepted) }
  let!(:demand_check) { create(:bedarfscheck_questionnaire) }

  def create_response(mandate, state="analyzed")
    create(
      :questionnaire_response,
      mandate:       mandate,
      questionnaire: demand_check,
      state:         state
    )
  end

  describe "#latest_demand_check" do
    it "should be nil, if no response is present" do
      expect(described_class.latest_demand_check(mandate)).to be_nil
    end

    it "should return the response, if one demand check had been analyzed" do
      expected = create_response(mandate)
      expect(described_class.latest_demand_check(mandate)).to eq(expected)
    end

    it "should return nil, if the mandate does not match" do
      create_response(create(:mandate, :accepted))
      expect(described_class.latest_demand_check(mandate)).to be_nil
    end

    it "should be nil, if no demand check had been analyzed yet" do
      create_response(mandate, "created")
      expect(described_class.latest_demand_check(mandate)).to be_nil
    end

    it "should return the latest response, if more than one had been analyzed" do
      now = Time.current

      Timecop.freeze(now)
      create_response(mandate)

      Timecop.travel(now.advance(seconds: 1))
      expected = create_response(mandate)

      expect(described_class.latest_demand_check(mandate)).to eq(expected)

      Timecop.return
    end
  end
end
