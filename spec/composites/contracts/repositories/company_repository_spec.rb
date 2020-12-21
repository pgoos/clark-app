# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/repositories/contract_repository"
require "composites/contracts/params"

RSpec.describe Contracts::Repositories::CompanyRepository, :integration do
  subject { described_class.new }

  describe "#companies_by_vertical" do
    let!(:vertical) { create(:vertical) }
    let!(:vertical2) { create(:vertical) }
    let!(:company1) { create(:company) }
    let!(:company2) { create(:company) }
    let!(:company3) { create(:company) }
    let!(:subcompany1) { create(:subcompany, verticals: [vertical], company: company1) }
    let!(:subcompany2) { create(:subcompany, verticals: [vertical], company: company2) }
    let!(:subcompany3) { create(:subcompany, verticals: [vertical2], company: company3) }

    it "returns companies based on vertical id provided" do
      result = subject.companies_by_vertical(vertical.ident)
      expect(result.size).to eq 2
      expect(result.map(&:ident).sort).to match [company1.ident, company2.ident].sort

      result = subject.companies_by_vertical(vertical2.ident)
      expect(result.size).to eq 1
      company = result.first
      expect(company.ident).to eq company3.ident
      expect(company.name).to eq company3.name
    end
  end
end
