# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Robo::CategoriesController, :integration, type: :controller do
  let(:admin) { create(:super_admin) }
  let!(:phv_category) { create(:category_phv) }

  before { login_admin(admin) }

  describe "GET #index" do
    context "when no search applied" do
      let!(:disabled_category) { create(:category) }

      it "returns all categories that is enabled_for_advice" do
        get :index, params: {locale: :de}

        categories = assigns(:categories)
        expect(categories).to include(phv_category)
        expect(categories).not_to include(disabled_category)
      end
    end

    context "when search by_name applied" do
      let!(:dental_category) { create(:category_dental) }

      it "returns only matched categories that is enabled_for_advice" do
        get :index, params: {locale: :de, by_name: dental_category.name}

        categories = assigns(:categories)
        expect(categories).to include(dental_category)
        expect(categories).not_to include(phv_category)
      end
    end
  end

  describe "PUT #toggle" do
    let!(:phv_category_rule) { create(:phv_category_rule) }

    it "should toggle enabled column" do
      put :toggle, params: {locale: :de, id: phv_category_rule.id}

      expect(phv_category_rule.reload.enabled).to be(false)
    end
  end

  describe "GET #category_rules" do
    let!(:phv_category_rule) { create(:phv_category_rule) }

    it "returns all category_rules for specified category" do
      get :category_rules, params: {locale: :de, id: phv_category.id}

      category_rules = assigns(:category_rules)
      expect(category_rules).to include(phv_category_rule)
    end
  end
end
