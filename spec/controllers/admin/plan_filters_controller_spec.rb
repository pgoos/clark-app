# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PlanFiltersController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/plan_filters")) }
  let(:admin) { create(:admin, role: role) }
  let(:household_property) { create(:category_hr) }
  let(:plan_filter) { create(:plan_filter, category: household_property) }
  let(:lifter) { Domain::OfferGeneration::PlanFilters.new }

  before do
    sign_in(admin)
    plan_filter
  end

  context "#index" do
    it "should render the overview" do
      get :index, params: {locale: :de}
      expect(response).to be_ok
      expect(subject).to render_template(:index)
    end
  end

  context "#update" do
    it "should open the edit form" do
      expect(Domain::OfferGeneration::PlanFilters).to receive(:new)
      get :edit, params: {id: plan_filter.id, locale: :de}
      expect(response).to be_ok
      expect(subject).to render_template(:edit)
    end

    it "should accept the form params" do
      expected_key = lifter.key_options(Category.household_contents_insurance_ident).first
      expected_values = %w[Testvalue1 Testvalue2]
      post :update, params: {
        id: plan_filter.id,
        locale: :de,
        plan_filter: {
          category_id: household_property.id,
          key:         expected_key,
          values:      expected_values
        }
      }
      plan_filter.reload
      expect(plan_filter.category_id).to eq(household_property.id)
      expect(plan_filter.key).to eq(expected_key)
      expect(plan_filter.values).to contain_exactly(*expected_values)
      expect(response).to redirect_to(admin_plan_filters_path)
    end
  end
end
