# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::SalesAdminsRepository, :integration do
  let!(:admin1) { create :admin, access_flags: %w[sales_consultation] }
  let!(:admin2) { create :admin, access_flags: %w[sales_consultation] }
  let!(:admin3) { create :admin, state: :inactive, access_flags: %w[sales_consultation] }
  let!(:admin4) { create :admin }

  describe "#select_with_sales_consultation_access" do
    context "admin with sales_consultation access_flags" do
      it "returns admin ids only for active with sales_consultation access_flags" do
        expect(subject.select_with_sales_consultation_access).to match_array([admin1.id, admin2.id])
      end
    end

    context "admin without sales_consultation access_flags" do
      let!(:admin4) { create :admin }
      let!(:admin5) { create :admin }

      it "returns admin ids only with sales_consultation access_flags" do
        expect(subject.select_with_sales_consultation_access).to match_array([admin1.id, admin2.id])
      end
    end
  end

  describe "#select_options_from_aoa" do
    let!(:admin6) { create :admin, access_flags: %w[sales_consultation] }

    context "admin with sales_consultation access_flags" do
      it "returns results only for provided consultant ids" do
        results = subject.select_options_from_aoa([admin1.id, admin2.id])

        expect(results.first).to be_a(Sales::Constituents::Opportunity::Entities::Admin)
        expect(results.map(&:id)).to match_array([admin1.id, admin2.id])
      end
    end

    context "results in the appropriate order" do
      it "returns the first admin on top" do
        results = subject.select_options_from_aoa([admin1.id, admin2.id])

        expect(results.first.id).to eq(admin1.id)
      end

      it "returns the second admin on top" do
        results = subject.select_options_from_aoa([admin2.id, admin1.id])

        expect(results.first.id).to eq(admin2.id)
      end
    end
  end

  describe "#select_options" do
    it "returns only active admins" do
      results = subject.select_options_from_aoa([admin1.id, admin2.id, admin4.id])

      expect(results.first).to be_a(Sales::Constituents::Opportunity::Entities::Admin)
      expect(results.map(&:id)).to match_array(Admin.active.map(&:id))
    end
  end

  describe "#sales_consultation_permitted?" do
    it "returns true if admin is active and has a sales_consultation flag" do
      results = subject.sales_consultation_permitted?(admin1.id)
      expect(results).to be_truthy
    end

    it "returns false if admin is inactive" do
      results = subject.sales_consultation_permitted?(admin3.id)
      expect(results).to be_falsey
    end

    it "returns false if admin does not have sales_consultation flag" do
      results = subject.sales_consultation_permitted?(admin4.id)
      expect(results).to be_falsey
    end
  end
end
