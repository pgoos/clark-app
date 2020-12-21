# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/repositories/plan_repository"

RSpec.describe Contracts::Repositories::PlanRepository, :integration do
  describe "#create" do
    subject { described_class.new.create(attributes) }

    let(:attributes) { attributes_for(:plan, category_ident: category.ident, company_ident: company.ident) }
    let(:category) { create(:category) }
    let(:company) { create(:company) }

    it "creates plan" do
      expect { subject }.to change(Plan, :count).by(1)
      expect(subject.category_id).to eq category.id
      expect(subject.company_id).to eq company.id
    end
  end
end
