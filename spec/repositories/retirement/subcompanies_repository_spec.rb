# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::SubcompaniesRepository, :integration do
  describe ".by_category" do
    let!(:plan)       { create(:plan, category: category, company: subcompany.company, subcompany: subcompany) }
    let(:subcompany)  { create(:subcompany, name: "Z") }
    let(:category)    { create(:category, ident: "e97a99d7") }

    context "when ident is retirement-related" do
      let(:subcompany2) { create(:subcompany, name: "B") }

      before do
        create(:plan, category: category, company: subcompany2.company, subcompany: subcompany2)

        @subcompanies = subject.by_category(category.ident).to_a
      end

      it "returns the sub-companies in alphabetical order" do
        expect(@subcompanies).to eq [subcompany2, subcompany]
      end
    end

    context "when same sub-company is in two or more plans" do
      before do
        create(:plan, category: category, company: subcompany.company, subcompany: subcompany)
      end

      it "returns the sub-company only once" do
        expect(subject.by_category(category.ident).to_a).to eq [subcompany]
      end
    end

    context "when bafin_id is nil" do
      let(:subcompany) { create(:subcompany, bafin_id: nil) }

      before do
        create(:plan, category: category, company: subcompany.company, subcompany: subcompany)
      end

      it { expect(subject.by_category(category.ident)).not_to include subcompany }
    end

    context "when ident is not retirement-related" do
      let(:category) { create(:category, :suhk) }

      it "raises ActiveRecord::ActiveRecordError" do
        expect { subject.by_category(category.ident) }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end
  end
end
