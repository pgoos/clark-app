# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CategoriesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/categories")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }
  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Filter
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  context "splits comma seperated included categories to array" do
    it "parses elements to integers" do
      controller.params = {category: {included_category_ids: "1,2,3"}}

      subject.send(:included_categories_from_string_to_array)

      expect(controller.params[:category][:included_category_ids]).to match_array([1, 2, 3])
    end

    it "eliminates duplicates" do
      controller.params = {category: {included_category_ids: "1,2,1,3,2,1"}}

      subject.send(:included_categories_from_string_to_array)

      expect(controller.params[:category][:included_category_ids]).to match_array([1, 2, 3])
    end

    it "eliminates elements that can't be parsed to numbers" do
      controller.params = {category: {included_category_ids: "1,foo,,2"}}

      subject.send(:included_categories_from_string_to_array)

      expect(controller.params[:category][:included_category_ids]).to match_array([1, 2])
    end
  end

  #
  # Actions
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
  describe "PATCH /toggle_available_for_offer_request" do
    let!(:category) { create(:category) }

    context "available_for_offer_request is false by default" do
      it "changes the available_for_offer_request value" do
        patch :toggle_available_for_offer_request, params: {id: category.id, locale: :de}
        expect(response).to redirect_to(admin_category_path(category))

        category.reload
        expect(category.available_for_offer_request).to be_falsey
      end
    end

    context "available_for_offer_request is true" do
      let!(:questionnaire_one) { create(:questionnaire) }

      before { category.questionnaires << questionnaire_one }

      it "changes the available_for_offer_request value" do
        patch :toggle_available_for_offer_request, params: {id: category.id, locale: :de}
        expect(response).to redirect_to(admin_category_path(category))

        category.reload
        expect(category.available_for_offer_request).to be_truthy
      end
    end
  end

  describe "PATCH /toggle_discontinued" do
    let!(:category) { create(:category) }

    context "discontinued is false" do
      it "changes the discontinued value" do
        patch :toggle_discontinued, params: {id: category.id, locale: :de}
        expect(response).to redirect_to(admin_category_path(category))

        category.reload
        expect(category.discontinued).to be_truthy
      end
    end

    context "discontinued is true" do
      before do
        category.update(discontinued: true)
      end

      it "changes the discontinued value" do
        patch :toggle_discontinued, params: {id: category.id, locale: :de}
        expect(response).to redirect_to(admin_category_path(category))

        category.reload
        expect(category.discontinued).to be_falsey
      end
    end
  end

  describe "GET /coverage_fields" do
    let!(:category) { create(:category) }
    let(:params) do
      {
        id: category.id,
        context: "Plan",
        locale: :de
      }
    end

    it "renders partial" do
      get :coverage_fields, params: params
      expect(response).to render_template(partial: "_coverage_fields")
    end

    context "when parent_context_id is empty" do
      before { params.merge!(parent_context_id: "") }

      it "does not check for parent plan" do
        expect(ParentPlan).not_to receive(:find_by)
        get :coverage_fields, params: params
      end
    end

    context "when parent_context_id is provided" do
      let(:parent_plan) { create(:parent_plan) }

      before { params.merge!(parent_context_id: parent_plan.id) }

      it "checks for parent plan" do
        expect(ParentPlan).to receive(:find_by).with({ id: parent_plan.id.to_s })
        get :coverage_fields, params: params
      end
    end
  end
end
