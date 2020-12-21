# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::OpenOpportunitiesCountRepository, :integration do
  let(:repository) { described_class.new }
  let(:beginning_of_a_month) { DateTime.new(2010, 4, 1, 0, 0, 0) }
  let(:admin_with_no_opportunity) { create(:admin) }

  describe "#open_opportunities_count_for" do
    describe "#find the correct data" do
      let(:middle_of_month) { beginning_of_a_month + 10.days }
      let(:opportunity_created_before_middle_of_month) {
        create(:opportunity, :created, created_at: middle_of_month - 5.days)
      }
      let(:opportunity_created_before_begin_of_month) {
        create(:opportunity, :created, created_at: middle_of_month - 15.days)
      }
      let(:opportunity_created_after_middle_of_month) {
        create(:opportunity, :created, created_at: middle_of_month + 1.day)
      }
      let(:opportunity_in_created) { create(:opportunity, :created, created_at: beginning_of_a_month) }
      let(:opportunity_in_initiation_phase) {
        create(:opportunity, :initiation_phase, created_at: beginning_of_a_month)
      }
      let(:opportunity_in_offer_phase) { create(:opportunity, :offer_phase, created_at: beginning_of_a_month) }
      let(:opportunity_in_completed) { create(:opportunity, :completed, created_at: beginning_of_a_month) }
      let(:opportunity_with_new_category_and_existing_admin) {
        create(:opportunity,
               :created,
               created_at: beginning_of_a_month,
               category: create(:category),
               admin: opportunity_in_created.admin)
      }

      it "finds all open opportunities regardless when it was created" do
        opportunities = [opportunity_created_before_begin_of_month, opportunity_created_after_middle_of_month]
        admin_ids = opportunities.map(&:admin_id).sort
        result = repository.open_opportunities_count_for([], [])
        expect(result.keys.sort).to eq(admin_ids)
        opportunities.each do |opportunity|
          admin_id = opportunity.admin_id
          category_ident = opportunity.category.ident
          expect(result[admin_id].keys.sort).to eq(%i[open_opportunities_category_counts open_opportunities].sort)
          expect(result[admin_id][:open_opportunities_category_counts].keys).to eq([category_ident])
          expect(result[admin_id][:open_opportunities_category_counts][category_ident]).to eq(1)
          expect(result[admin_id][:open_opportunities]).to eq(1)
        end
      end

      it "finds only open opportunities" do
        opportunity_in_completed
        opportunities_to_find = [opportunity_in_created, opportunity_in_initiation_phase, opportunity_in_offer_phase]
        result = repository.open_opportunities_count_for([], [])
        admin_ids = opportunities_to_find.map(&:admin_id).sort
        expect(result.keys.sort).to eq(admin_ids)
        opportunities_to_find.each do |opportunity_to_found|
          admin_id = opportunity_to_found.admin_id
          category_ident = opportunity_to_found.category.ident
          expect(result[admin_id].keys.sort).to eq(%i[open_opportunities_category_counts open_opportunities].sort)
          expect(result[admin_id][:open_opportunities_category_counts].keys).to eq([category_ident])
          expect(result[admin_id][:open_opportunities_category_counts][category_ident]).to eq(1)
          expect(result[admin_id][:open_opportunities]).to eq(1)
        end
      end

      it "uses consultant_ids if passed" do
        consultant_ids = [opportunity_in_created.admin_id, admin_with_no_opportunity.id]
        admin_id = opportunity_in_created.admin_id
        result = repository.open_opportunities_count_for(consultant_ids, [])
        expect(result.keys.sort).to eq(consultant_ids.sort)
        expect(result[admin_id].keys.sort).to eq(%i[open_opportunities_category_counts open_opportunities].sort)
        expect(result[admin_with_no_opportunity.id]).to be_nil
      end

      it "uses category_ids if passed" do
        opportunity_with_new_category_and_existing_admin
        category_ids = [opportunity_in_created.category_id]
        admin_id = opportunity_in_created.admin_id
        category_ident = opportunity_in_created.category.ident
        result = repository.open_opportunities_count_for([], category_ids)
        expect(result[admin_id][:open_opportunities_category_counts].keys).to eq([category_ident])
      end
    end

    describe "#calculate the count correctly" do
      let(:assigned_admin) { create(:admin) }
      let(:category_for_many_opportunities) { create(:category) }
      let!(:opportunities_with_known_category) {
        create_list(:opportunity, 2,
                    :created,
                    admin: assigned_admin,
                    created_at: beginning_of_a_month,
                    category: category_for_many_opportunities)
      }
      let!(:opportunity_with_unknown_category) {
        create(:opportunity, :created, admin: assigned_admin, created_at: beginning_of_a_month)
      }

      it "counts the open opportunity correctly" do
        result = repository.open_opportunities_count_for([], [])
        expect(result.keys).to eq([assigned_admin.id])
        result[assigned_admin.id][:open_opportunities_category_counts].each do |(category_ident, count)|
          expect(count).to eq(category_ident == category_for_many_opportunities.ident ? 2 : 1)
        end
        expect(result[assigned_admin.id][:open_opportunities]).to eq(3)
      end
    end
  end
end
