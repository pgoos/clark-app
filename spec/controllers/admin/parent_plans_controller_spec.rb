# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ParentPlansController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/parent_plans")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET #index" do
    context "with plan coverages" do
      let(:subcompany) { create(:subcompany) }
      let!(:plan1) { create(:parent_plan, :with_stubbed_coverages, subcompany: subcompany) }
      let!(:plan2) { create(:parent_plan, subcompany: subcompany) }

      it "returns only the correct plans" do
        get :index, params: {locale: :de}
        expect(response).to have_http_status(:ok)
        expect(assigns(:parent_plans)).to match_array([plan1, plan2])
      end

      it "filters by plans with coverages" do
        get :index, params: {locale: :de, with_coverages: true}
        expect(response).to have_http_status(:ok)
        expect(assigns(:parent_plans)).to match_array([plan1])
      end
    end

    context "without pagination" do
      let!(:plan1) { create(:parent_plan) }
      let!(:plan2) { create(:parent_plan) }

      it "paginates by default" do
        get :index, params: {locale: :de, with_coverages: true}
        plans = assigns(:parent_plans)
        expect(plans).to be_a(ActiveRecord::Relation)
        expect(plans.limit_value).to eq Kaminari.config.default_per_page
      end

      it "does not paginate with query parameter" do
        get :index, params: {locale: :de, with_coverages: true, without_pagination: true}
        plans = assigns(:parent_plans)
        expect(plans).to be_a(ActiveRecord::Relation)
        expect(plans.limit_value).to eq nil
      end
    end

    context "ordering by name" do
      let!(:plan1) { create(:parent_plan, name: "Comfort") }
      let!(:plan2) { create(:parent_plan, name: "Basic") }
      let!(:plan3) { create(:parent_plan, name: "Quality") }

      it "paginates by default" do
        get :index, params: {locale: :de, order: "name_asc"}
        plans = assigns(:parent_plans)
        expect(plans).to eq [plan2, plan1, plan3]
      end
    end
  end

  describe "POST create" do
    let(:company) { create(:company) }
    let(:category) { create(:category) }
    let(:attributes) do
      attributes_for(:parent_plan, company_id: company.id, category_id: category.id)
    end

    context "admin can create plan with state begin date" do
      before do
        allow_any_instance_of(Admin).to receive(:can?).with("create_plans_with_plan_states").and_return(true)
      end

      context "params contain plane_state_begin" do
        it "creates plan" do
          post :create, params: {locale: I18n.locale, parent_plan: attributes}
          expect(ParentPlan.last.name).to eq attributes[:name]
        end

        context "params does not contain plane_state_begin" do
          it "creates plan" do
            post :create, params: {locale: I18n.locale, parent_plan: attributes.except(:plan_state_begin)}
            expect(ParentPlan.last.name).to eq attributes[:name]
          end
        end
      end
    end

    context "admin cant create plan with state begin date" do
      before do
        allow_any_instance_of(Admin).to receive(:can?).with("create_plans_with_plan_states").and_return(false)
      end

      context "params does not contain plan_state_begin" do
        it "creates plan" do
          post :create, params: {locale: I18n.locale, parent_plan: attributes.except(:plan_state_begin)}
          expect(ParentPlan.last.name).to eq attributes[:name]
        end
      end

      context "params contain plane_state_begin" do
        it "raises exception" do
          expect {
            post :create, params: {locale: I18n.locale, parent_plan: attributes}
          }.to raise_exception(Admin::BaseController::NotAuthorized)
        end
      end
    end
  end
end
