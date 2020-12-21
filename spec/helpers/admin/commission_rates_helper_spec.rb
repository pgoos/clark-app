# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CommissionRatesHelper do
  describe "#subcompanies_for" do
    let(:commission_rate) { create(:commission_rate, subcompany: subcompany1, category: category) }
    let(:category) { create(:category) }
    let(:company) { create(:company) }
    let(:subcompany1) { create(:subcompany, verticals: [category.vertical], company: company) }
    let!(:subcompany2) { create(:subcompany, company: company) }

    it "returns subcompanies based on product's category" do
      expect(helper.subcompanies_for(commission_rate).size).to eq 1
    end
  end
end
